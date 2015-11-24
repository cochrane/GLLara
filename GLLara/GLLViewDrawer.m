//
//  GLLViewDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLViewDrawer.h"

#import <OpenGL/gl3.h>

#import "NSColor+Color32Bit.h"
#import "GLLAmbientLight.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLUniformBlockBindings.h"
#import "GLLSceneDrawer.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"

struct GLLLightBlock
{
	vec_float4 cameraLocation;
	float ambientColor[4];
	struct GLLLightUniformBlock lights[3];
};

@interface GLLViewDrawer ()
{
	NSArray *lights; // Always one ambient and three directional ones. Don't watch for mutations.
	
	GLuint transformBuffer;
	GLuint lightBuffer;
	BOOL needsUpdateMatrices;
	BOOL needsUpdateLights;
}

- (void)_updateLights;
- (void)_updateMatrices;

@end

@implementation GLLViewDrawer

- (id)initWithManagedSceneDrawer:(GLLSceneDrawer *)drawer camera:(GLLCamera *)camera context:(NSOpenGLContext *)openGLContext pixelFormat:(NSOpenGLPixelFormat *)format;
{
	if (!(self = [super init])) return nil;

	_context = openGLContext;
	_pixelFormat = format;
	_camera = camera;
	_sceneDrawer = drawer;
	__weak id weakSelf = self;
	[[NSNotificationCenter defaultCenter] addObserverForName:GLLSceneDrawerNeedsUpdateNotification object:_sceneDrawer queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
		[[weakSelf view] setNeedsDisplay:YES];
	}];
	[_sceneDrawer addObserver:self forKeyPath:@"needsRedraw" options:0 context:0];
	
	lights = [[NSMutableArray alloc] initWithCapacity:4];
	
	// Prepare light buffer.
	glGenBuffers(1, &lightBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
	glBufferData(GL_UNIFORM_BUFFER, sizeof(struct GLLLightBlock), NULL, GL_STREAM_DRAW);
	
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
	glGenBuffers(1, &transformBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
	glBufferData(GL_UNIFORM_BUFFER, sizeof(mat_float16), NULL, GL_STREAM_DRAW);
	[self.camera addObserver:self forKeyPath:@"viewProjectionMatrix" options:0 context:0];
	
	// Other necessary render state. Thanks to Core Profile, that got cut down a lot.
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_MULTISAMPLE);
	glClearColor(0.2, 0.2, 0.2, 0.0);
	
	glBlendColor(0, 0, 0, 1.0);
	glBlendEquationSeparate(GL_FUNC_ADD, GL_MAX);
	glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA, GL_DST_ALPHA);
	
	glEnable(GL_CULL_FACE);
	glFrontFace(GL_CW);
	
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
	[self.sceneDrawer removeObserver:self forKeyPath:@"needsRedraw"];
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

- (void)setView:(NSView *)view
{
	_view = view;
	_view.needsDisplay = YES;
}

- (void)drawShowingSelection:(BOOL)selection;
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	if (needsUpdateMatrices) [self _updateMatrices];
	if (needsUpdateLights) [self _updateLights];
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
	
	[self.sceneDrawer drawShowingSelection:selection];
}

- (void)drawWithNewStateShowingSelection:(BOOL)selection;
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (needsUpdateMatrices) [self _updateMatrices];
    if (needsUpdateLights) [self _updateLights];
    glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
    glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
    
    [self.sceneDrawer drawWithNewStateShowingSelection:selection];
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
									 kCGImageAlphaLast,
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
			mat_float16 combinedMatrix = simd_mat_mul(flipMatrix, cameraMatrix);
			mat_float16 partOfCameraMatrix = simd_orthoMatrix((x/size.width)*2.0-1.0, ((x+width)/size.width)*2.0-1.0, (y/size.height)*2.0-1.0, ((y+height)/size.height)*2.0-1.0, 1, -1);
			combinedMatrix = simd_mat_mul(partOfCameraMatrix, combinedMatrix);
			
			glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
			glBufferData(GL_UNIFORM_BUFFER, sizeof(combinedMatrix), NULL, GL_STREAM_DRAW);
            
            mat_float16 *data = glMapBuffer(GL_UNIFORM_BUFFER, GL_WRITE_ONLY);
            memcpy(data, &combinedMatrix, sizeof(combinedMatrix));
            glUnmapBuffer(GL_UNIFORM_BUFFER);
			
			// Enable blend for entire scene. That way, new alpha are correctly combined with values in the buffer (instead of stupidly overwriting them), giving the rendered image a correct alpha channel.
			glEnable(GL_BLEND);
			
			[self drawWithNewStateShowingSelection:NO];
			
			glBindFramebuffer(GL_FRAMEBUFFER, 0);
			
			glFlush();
			
			// Clean up and inform background thread to start loading.
			finishedTextures += 1;
			dispatch_semaphore_signal(texturesReady);
		}
	}
	
	dispatch_semaphore_wait(downloadReady, DISPATCH_TIME_FOREVER);
	glViewport(0, 0, self.camera.actualWindowWidth, self.camera.actualWindowHeight);
	glDeleteFramebuffers(1, &framebuffer);
	glDeleteRenderbuffers(1, &depthRenderbuffer);
	glCullFace(GL_BACK);
	glEnable(GL_MULTISAMPLE);
	
	needsUpdateMatrices = YES;
	self.view.needsDisplay = YES;
}

#pragma mark - Private methods

- (void)_updateLights;
{
	struct GLLLightBlock lightData;
	
	// Camera position
	lightData.cameraLocation = self.camera.cameraWorldPosition;
	
	// Ambient
	GLLAmbientLight *ambient = lights[0];
	[ambient.color get128BitRGBAComponents:lightData.ambientColor];
	
	// Diffuse + Specular
	for (NSUInteger i = 0; i < 3; i++)
	{
		GLLDirectionalLight *light = lights[i+1];
		lightData.lights[i] = light.uniformBlock;
	}
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
	glBufferSubData(GL_UNIFORM_BUFFER, 0, sizeof(lightData), &lightData);
	
	needsUpdateLights = NO;
}

- (void)_updateMatrices
{
	mat_float16 viewProjection = self.camera.viewProjectionMatrix;
	
	// Set the view projection matrix.
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
	glBufferSubData(GL_UNIFORM_BUFFER, 0, sizeof(viewProjection), &viewProjection);
	
	needsUpdateMatrices = NO;
}

@end
