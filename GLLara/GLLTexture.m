//
//  GLLTexture.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLTexture.h"

#import <Accelerate/Accelerate.h>
#import <ApplicationServices/ApplicationServices.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLRenderers.h>

#import "GLLDDSFile.h"

#ifndef kCGLRendererIntelHD4000ID
#define kCGLRendererIntelHD4000ID 0x0024400
#endif

#pragma mark - Private DDS loading functions

GLenum _dds_get_compressed_texture_format(GLLDDSFile *file)
{
	switch(file.dataFormat)
	{
		case GLL_DDS_DXT1:
			return GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;
		case GLL_DDS_DXT3:
			return GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;
		case GLL_DDS_DXT5:
			return GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
			
		default:
			return 0;
	}
}

void _dds_get_texture_format(GLLDDSFile *file, GLenum *format, GLenum *type)
{
	*format = 0;
	*type = 0;
	switch(file.dataFormat)
	{
		case GLL_DDS_RGB_8:
			*format = GL_RGB;
			*type = GL_UNSIGNED_BYTE;
			break;
		case GLL_DDS_RGB_565:
			*format = GL_RGB;
			*type = GL_UNSIGNED_SHORT_5_6_5;
			break;
		case GLL_DDS_ARGB_8:
			*format = GL_BGRA;
			*type = GL_UNSIGNED_INT_8_8_8_8_REV;
			break;
		case GLL_DDS_ARGB_4:
			*format = GL_BGRA;
			*type = GL_UNSIGNED_SHORT_4_4_4_4_REV;
			break;
		case GLL_DDS_ARGB_1555:
			*format = GL_BGRA;
			*type = GL_UNSIGNED_SHORT_1_5_5_5_REV;
			break;
		case GLL_DDS_XRGB_8:
			*format = GL_BGR;
			*type = GL_UNSIGNED_INT_8_8_8_8_REV;
			break;
		
		default:
			*format = 0;
			*type = 0;
	}
}

Boolean _dds_upload_texture_data(GLLDDSFile *file, CFIndex mipmapLevel)
{
	CFIndex size;
	CFIndex width;
	CFIndex height;
	NSData *data;
	
	width = file.width >> mipmapLevel;
	height = file.height >> mipmapLevel;
	if (!width || !height) return 0;
	
	data = [file dataForMipmapLevel:mipmapLevel];
	if (!data) return 0;
    const void *byteData = data.bytes;
    size = data.length;
	if (size == 0)
	{
		return 0;
	}
    
	if (file.isCompressed)
		glCompressedTexImage2D(GL_TEXTURE_2D, (GLsizei) mipmapLevel, _dds_get_compressed_texture_format(file), (GLsizei) width, (GLsizei) height, 0, (GLsizei) size, byteData);
	else
	{
		GLenum format;
		GLenum type;
        _dds_get_texture_format(file, &format, &type);
		if (format == 0 || type == 0)
			return 0;
		glTexImage2D(GL_TEXTURE_2D, (GLsizei) mipmapLevel, GL_RGBA, (GLsizei) width, (GLsizei) height, 0, format, type, byteData);
	}
    
	return 1;
}

static NSOperationQueue *imageInformationQueue = nil;
static GLint renderer;
static BOOL isIntel;

@interface GLLTexture ()
{
	dispatch_source_t dispatchSource;
	int fileHandle;
}

- (BOOL)_loadDDSTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error;
- (void)_loadCGCompatibleTexture:(NSData *)data;

- (BOOL)_loadDataError:(NSError *__autoreleasing*)error;

@end

@implementation GLLTexture

+ (void)initialize
{
	imageInformationQueue = [[NSOperationQueue alloc] init];
	imageInformationQueue.maxConcurrentOperationCount = 1;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
	return [NSSet setWithObject:@"url"];
}

- (id)initWithURL:(NSURL *)url error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(url);
	NSAssert(CGLGetCurrentContext() != NULL, @"Context must exist");
	
	if (!(self = [super init])) return nil;
	
	[NSFileCoordinator addFilePresenter:self];
	
	self.url = url.absoluteURL;
	
	// Find out whether we're using an Intel renderer
	if (renderer == 0)
	{
		CGLContextObj context = CGLGetCurrentContext();
		CGLGetParameter(context, kCGLCPCurrentRendererID, &renderer);
		renderer &= kCGLRendererIDMatchingMask;
		
		// Compare with Intel HD (3000) and HD 4000. Earlier Intel GPU's aren't supported by 10.8 anyway.
		isIntel = (renderer == kCGLRendererIntelHD4000ID) || (renderer == kCGLRendererIntelHDID);
	}
	
	const char *path = self.url.path.fileSystemRepresentation;
	fileHandle = open(path, O_EVTONLY);
	
	__block __weak id weakSelf = self;
	
	dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fileHandle, DISPATCH_VNODE_WRITE, dispatch_get_main_queue());
	dispatch_source_set_event_handler(dispatchSource, ^(){
		[weakSelf _loadDataError:NULL];
	});
	dispatch_resume(dispatchSource);
	
	glGenTextures(1, &_textureID);
	
	BOOL success = [self _loadDataError:error];
	if (!success) return nil;
	
	return self;
}

- (void)unload;
{
	glDeleteTextures(1, &_textureID);
	_textureID = 0;
	self.url = nil;
}

- (void)dealloc
{
	close(fileHandle);
	NSAssert(_textureID == 0, @"did not call unload before dealloc");
}

#pragma mark - File Presenter

- (NSURL *)presentedItemURL
{
	return self.url;
}

- (NSOperationQueue *)presentedItemOperationQueue
{
	return imageInformationQueue;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler
{
	glBindTexture(GL_TEXTURE_2D, _textureID);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	
	completionHandler(nil);
}

- (void)presentedItemDidChange
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _loadDataError:NULL];
	});
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
	self.url = newURL;
}

#pragma mark - Private methods

- (BOOL)_loadDataError:(NSError *__autoreleasing*)error;
{
	NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
	
	__block NSError *internalError = nil;
	NSError *coordinationError;
	[coordinator coordinateReadingItemAtURL:self.url options:NSFileCoordinatorReadingResolvesSymbolicLink error:&coordinationError byAccessor:^(NSURL *newURL){
		NSAssert(CGLGetCurrentContext() != NULL, @"Context must exist");
		
		NSData *data = [NSData dataWithContentsOfURL:newURL options:0 error:&internalError];
		
		// Ensure that memcmp does not error out.
		if (data.length < 4) return;
		
		// Load texture
		glBindTexture(GL_TEXTURE_2D, _textureID);
		
		if (memcmp(data.bytes, "DDS ", 4) == 0)
			[self _loadDDSTextureWithData:data error:&internalError];
		else
			[self _loadCGCompatibleTexture:data];
		
		if (internalError != nil) NSLog(@"Error loading texture %@: %@", self.url, internalError);
	}];
	
	if (coordinationError)
	{
		if (error) *error = coordinationError;
		return NO;
	}
	else if (internalError)
	{
		if (error) *error = internalError;
		return NO;
	}
	else return YES;
}

- (BOOL)_loadDDSTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error;
{
	NSError *ddsLoadingError = nil;
	GLLDDSFile *file = [[GLLDDSFile alloc] initWithData:data error:&ddsLoadingError];
	if (!file)
	{
		if (error)
			*error = [NSError errorWithDomain:@"Textures" code:12 userInfo:@{
				   NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"DDS File %@ couldn't be opened: %@", @"DDSOpenData returned NULL"), self.url.lastPathComponent, ddsLoadingError.userInfo[NSLocalizedDescriptionKey]],
	   NSLocalizedRecoverySuggestionErrorKey : ddsLoadingError.userInfo[NSLocalizedRecoverySuggestionErrorKey],
						NSUnderlyingErrorKey : ddsLoadingError
					  }];
		return NO;
	}
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	
	NSUInteger mipmap = 0;
	while (_dds_upload_texture_data(file, mipmap))
		mipmap += 1;
	
	glGenerateMipmap(GL_TEXTURE_2D);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 16.0f);
	
	return YES;
}
- (void)_loadCGCompatibleTexture:(NSData *)data;
{
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
	CFDictionaryRef dict = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
	CFIndex width, height;
	CFNumberGetValue(CFDictionaryGetValue(dict, kCGImagePropertyPixelWidth), kCFNumberCFIndexType, &width);
	CFNumberGetValue(CFDictionaryGetValue(dict, kCGImagePropertyPixelHeight), kCFNumberCFIndexType, &height);
	CFRelease(dict);
	
	unsigned char *bufferData = calloc(width * height, 4);
	CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	CFRelease(source);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef cgContext = CGBitmapContextCreate(bufferData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
	NSAssert(cgContext != NULL, @"Could not create CG Context");
	
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawImage(cgContext, CGRectMake(0.0f, 0.0f, (CGFloat) width, (CGFloat) height), cgImage);
	CGContextRelease(cgContext);
	CGImageRelease(cgImage);
	
	// Unpremultiply the texture data. I wish I could get it unpremultiplied from the start, but CGImage doesn't allow that. Just using premultiplied sounds swell, but it messes up my blending in OpenGL.
	unsigned char *unpremultipliedBufferData = calloc(width * height, 4);
	vImage_Buffer input = { .height = height, .width = width, .rowBytes = 4*width, .data = bufferData };
	vImage_Buffer output = { .height = height, .width = width, .rowBytes = 4*width, .data = unpremultipliedBufferData };
	vImageUnpremultiplyData_ARGB8888(&input, &output, 0);
	free(bufferData);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, isIntel ? GL_LINEAR : GL_LINEAR_MIPMAP_LINEAR);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) width, (GLsizei) height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, unpremultipliedBufferData);
	
	if (!isIntel)
		glGenerateMipmap(GL_TEXTURE_2D);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 16.0f);
	
	free(unpremultipliedBufferData);
}

@end
