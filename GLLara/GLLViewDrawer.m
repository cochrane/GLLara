//
//  GLLViewDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLViewDrawer.h"

#import "NSColor+Color32Bit.h"
#import "GLLAmbientLight.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLNotifications.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"

#import "GLLara-Swift.h"

#import "GLLResourceIDs.h"
#import "GLLRenderParameters.h"
#import "GLLResourceManager.h"

@interface GLLViewDrawer ()
{
	NSArray<NSManagedObject *> *lights; // Always one ambient and three directional ones. Don't watch for mutations.
    
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
	
    id<MTLBuffer> transformBuffer;
    id<MTLBuffer> lightBuffer;
	BOOL needsUpdateMatrices;
	BOOL needsUpdateLights;
}

- (void)_updateLights;
- (void)_updateMatrices;

@end

@implementation GLLViewDrawer

- (id)initWithManagedSceneDrawer:(GLLSceneDrawer *)drawer camera:(GLLCamera *)camera view:(GLLView *)view;
{
	if (!(self = [super init])) return nil;

    _view = view;
    device = view.device;
    commandQueue = [device newCommandQueue];
    _view.delegate = self;
    
	_camera = camera;
	_sceneDrawer = drawer;
	__weak id weakSelf = self;
	[[NSNotificationCenter defaultCenter] addObserverForName:GLLSceneDrawerNeedsUpdateNotification object:_sceneDrawer queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
		[[weakSelf view] setNeedsDisplay:YES];
	}];
	
	lights = [[NSMutableArray alloc] initWithCapacity:4];
	
	// Prepare light buffer.
    lightBuffer = [device newBufferWithLength:sizeof(struct GLLLightsBuffer) options:MTLResourceStorageModeManaged];
    lightBuffer.label = @"global-lights";
	
	// Load existing lights
	NSFetchRequest *allLightsRequest = [[NSFetchRequest alloc] init];
	allLightsRequest.entity = [NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:drawer.managedObjectContext];
	allLightsRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	lights = [drawer.managedObjectContext executeFetchRequest:allLightsRequest error:NULL];
	
	NSAssert(lights.count == 4, @"There are not four lights.");
	
	// Register for ambient light color updates
	[lights[0] addObserver:self forKeyPath:@"color" options:0 context:NULL];
	// Register for directional light color updates
	for (int i = 0; i < 3; i++)
		[lights[i + 1] addObserver:self forKeyPath:@"uniformBlock" options:0 context:NULL];
	
	// Transform buffer
    transformBuffer = [device newBufferWithLength:sizeof(mat_float16) options:MTLResourceStorageModeManaged];
    transformBuffer.label = @"global-transform";
	[self.camera addObserver:self forKeyPath:@"viewProjectionMatrix" options:0 context:0];
	
	// Other necessary render state. Thanks to Metal, that got cut down a lot.
    view.clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0);
	
	needsUpdateMatrices = YES;
	needsUpdateLights = YES;
	
	return self;
}

- (void)dealloc
{
	[lights[0] removeObserver:self forKeyPath:@"color"];
	
	for (int i = 0; i < 3; i++)
		[lights[i + 1] removeObserver:self forKeyPath:@"uniformBlock"];
	
	[self.camera removeObserver:self forKeyPath:@"viewProjectionMatrix"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"viewProjectionMatrix"])
	{
		needsUpdateMatrices = YES;
		needsUpdateLights = YES;
		self.view.needsDisplay = YES;
	}
	else if ([keyPath isEqual:@"uniformBlock"] || [keyPath isEqual:@"color"])
	{
		needsUpdateLights = YES;
		self.view.needsDisplay = YES;
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)drawShowingSelection:(BOOL)selection into:(id<MTLRenderCommandEncoder>)commandEncoder;
{
	if (needsUpdateMatrices) [self _updateMatrices];
	if (needsUpdateLights) [self _updateLights];
    
    [commandEncoder setVertexBuffer:transformBuffer offset:0 atIndex:GLLVertexInputIndexViewProjection];
    [commandEncoder setVertexBuffer:lightBuffer offset:0 atIndex:GLLVertexInputIndexLights];
    [commandEncoder setFragmentBuffer:lightBuffer offset:0 atIndex:GLLFragmentBufferIndexLights];
	
    [self.sceneDrawer drawWithShowingSelection:selection into:commandEncoder];
}

#pragma mark - Image rendering

- (void)writeImageToURL:(NSURL *)url fileType:(NSString *)type size:(CGSize)size;
{
	NSUInteger dataSize = size.width * size.height * 4;
	void *data = malloc(dataSize);
	[self renderImageOfSize:size toColorBuffer:data];
	
	CFDataRef imageData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, data, dataSize, kCFAllocatorMalloc);
	CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(imageData);
	CFRelease(imageData);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
	CGImageRef image = CGImageCreate(size.width,
									 size.height,
									 8,
									 32,
									 4 * size.width,
									 colorSpace,
									 (CGBitmapInfo) kCGImageAlphaLast,
									 dataProvider,
									 NULL,
									 YES,
									 kCGRenderingIntentDefault);
	
	CGDataProviderRelease(dataProvider);
	CGColorSpaceRelease(colorSpace);
	
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef) url, (__bridge CFStringRef) type, 1, NULL);
	CGImageDestinationAddImage(imageDestination, image, NULL);
	CGImageDestinationFinalize(imageDestination);
	
	CGImageRelease(image);
	CFRelease(imageDestination);
}

- (void)renderImageOfSize:(CGSize)size toColorBuffer:(void *)colorData;
{
    /*
	// What is the largest tile that can be rendered?
	[self.context makeCurrentContext];
	GLint maxTextureSize, maxRenderbufferSize;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
	glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderbufferSize);
	// Divide max size by 2; it seems some GPUs run out of steam otherwise.
	GLint maxSize = MIN(maxTextureSize, maxRenderbufferSize) / 4;
	
	// Prepare framebuffer (without texture; a new one is created for every tile)
	GLuint framebuffer;
	glGenFramebuffers(1, &framebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	
	GLuint depthRenderbuffer;
	glGenRenderbuffers(1, &depthRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    
    // Get old viewport. Oh god, a glGet, how slow and annoying
    GLint oldViewport[4];
    glGetIntegerv(GL_VIEWPORT, oldViewport);
	
	// Prepare textures
	GLuint numTextures = ceil(size.width / maxSize) * ceil(size.height / maxSize);
	GLuint *textureNames = calloc(sizeof(GLuint), numTextures);
	glGenTextures(numTextures, textureNames);
	
	// Pepare background thread. This waits until textures are done, then loads them into colorData.
	__block NSUInteger finishedTextures = 0;
	__block dispatch_semaphore_t texturesReady = dispatch_semaphore_create(0);
	__block dispatch_semaphore_t downloadReady = dispatch_semaphore_create(0);
	
	NSOpenGLContext *backgroundLoadingContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:self.context];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[backgroundLoadingContext makeCurrentContext];
		NSUInteger downloadedTextures = 0;
		while (downloadedTextures < numTextures)
		{
			dispatch_semaphore_wait(texturesReady, DISPATCH_TIME_FOREVER);
			
			GLint row = (GLint) downloadedTextures / (GLint) ceil(size.width / maxSize);
			GLint column = (GLint) downloadedTextures % (GLint) ceil(size.width / maxSize);
			
			glPixelStorei(GL_PACK_ROW_LENGTH, size.width);
			glPixelStorei(GL_PACK_SKIP_ROWS, row * maxSize);
			glPixelStorei(GL_PACK_SKIP_PIXELS, column * maxSize);
			
			glBindTexture(GL_TEXTURE_2D, textureNames[downloadedTextures]);
			glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, colorData);
			
			glDeleteTextures(1, &textureNames[downloadedTextures]);
			
			downloadedTextures += 1;
		}
		dispatch_semaphore_signal(downloadReady);
	});
	
	mat_float16 cameraMatrix = [self.camera viewProjectionMatrixForAspectRatio:size.width / size.height];
	
	// Set up state for rendering
	// We invert drawing here so it comes out right in the file. That makes it necessary to turn cull face around.
	glCullFace(GL_FRONT);
	glDisable(GL_MULTISAMPLE);
	
	// Render
	for (NSUInteger y = 0; y < size.height; y += maxSize)
	{
		for (NSUInteger x = 0; x < size.width; x += maxSize)
		{
			// Setup size
			GLuint width = MIN(size.width - x, maxSize);
			GLuint height = MIN(size.height - y, maxSize);
			glViewport(0, 0, width, height);
			
			glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
			
			// Setup buffers + textures
			glBindTexture(GL_TEXTURE_2D, textureNames[finishedTextures]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureNames[finishedTextures], 0);
			
			glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
			glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, width, height);
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
			
			// Setup matrix. First, flip the y direction because OpenGL textures are not the same way around as CGImages. Then, use ortho to select the part that corresponds to the current tile.
			mat_float16 flipMatrix = (mat_float16) { {1,0,0,0},{0, -1, 0,0}, {0,0,1,0}, {0,0,0,1} };
			mat_float16 combinedMatrix = simd_mul(flipMatrix, cameraMatrix);
			mat_float16 partOfCameraMatrix = simd_orthoMatrix((x/size.width)*2.0-1.0, ((x+width)/size.width)*2.0-1.0, (y/size.height)*2.0-1.0, ((y+height)/size.height)*2.0-1.0, 1, -1);
			combinedMatrix = simd_mul(partOfCameraMatrix, combinedMatrix);
			
			glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
			glBufferData(GL_UNIFORM_BUFFER, sizeof(combinedMatrix), NULL, GL_STREAM_DRAW);
            
            mat_float16 *data = glMapBuffer(GL_UNIFORM_BUFFER, GL_WRITE_ONLY);
            memcpy(data, &combinedMatrix, sizeof(combinedMatrix));
            glUnmapBuffer(GL_UNIFORM_BUFFER);
			
			// Enable blend for entire scene. That way, new alpha are correctly combined with values in the buffer (instead of stupidly overwriting them), giving the rendered image a correct alpha channel.
			glEnable(GL_BLEND);
			
			[self drawShowingSelection:NO resetState:YES];
			
			glBindFramebuffer(GL_FRAMEBUFFER, 0);
			
			glFlush();
			
			// Clean up and inform background thread to start loading.
			finishedTextures += 1;
			dispatch_semaphore_signal(texturesReady);
		}
	}
	
	dispatch_semaphore_wait(downloadReady, DISPATCH_TIME_FOREVER);
	glViewport(oldViewport[0], oldViewport[1], oldViewport[2], oldViewport[3]);
	glDeleteFramebuffers(1, &framebuffer);
	glDeleteRenderbuffers(1, &depthRenderbuffer);
	glCullFace(GL_BACK);
	glEnable(GL_MULTISAMPLE);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
	
	needsUpdateMatrices = YES;
	self.view.needsDisplay = YES;
     */
}

#pragma mark - Private methods

- (void)_updateLights;
{
	struct GLLLightsBuffer lightData;
	
	// Camera position
    lightData.cameraPosition = self.camera.cameraWorldPosition;
	
	// Ambient
	GLLAmbientLight *ambient = (GLLAmbientLight *) lights[0];
	[ambient.color get128BitRGBAComponents:(float*) &lightData.ambientColor];
	
	// Diffuse + Specular
	for (NSUInteger i = 0; i < 3; i++)
	{
		GLLDirectionalLight *light = (GLLDirectionalLight *) lights[i+1];
		lightData.lights[i] = light.uniformBlock;
	}
    
    memcpy(lightBuffer.contents, &lightData, sizeof(lightData));
    [lightBuffer didModifyRange:NSMakeRange(0, sizeof(lightData))];
	
	needsUpdateLights = NO;
}

- (void)_updateMatrices
{
	mat_float16 viewProjection = self.camera.viewProjectionMatrix;
	
	// Set the view projection matrix.
    memcpy(transformBuffer.contents, &viewProjection, sizeof(viewProjection));
    [transformBuffer didModifyRange:NSMakeRange(0, sizeof(viewProjection))];
	
	needsUpdateMatrices = NO;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.camera.actualWindowWidth = size.width;
    self.camera.actualWindowHeight = size.height;
}

- (void)drawInMTKView:(MTKView *)view {
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) {
        return;
    }
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
    
    [commandEncoder setTriangleFillMode:MTLTriangleFillModeFill];
    [commandEncoder setFrontFacingWinding:MTLWindingClockwise];
    [commandEncoder setCullMode:MTLCullModeBack];
    [commandEncoder setDepthStencilState: _sceneDrawer.resourceManager.normalDepthStencilState];
    [commandEncoder setFragmentSamplerState:_sceneDrawer.resourceManager.metalSampler atIndex:0];
    [commandEncoder setBlendColorRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    
    [self drawShowingSelection: self.view.showSelection into: commandEncoder];
    
    [commandEncoder endEncoding];
    id<MTLDrawable> drawable = view.currentDrawable;
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
