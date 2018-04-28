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
#import <AppKit/AppKit.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLRenderers.h>

#import "GLLDDSFile.h"
#import "GLLNotifications.h"
#import "GLLPreferenceKeys.h"
#import "GLLTiming.h"

NSString *GLLTextureChangeNotification = @"GLL Texture Change Notification";

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

void _dds_get_texture_format(GLLDDSFile *file, GLenum *internalFormat, GLenum *format, GLenum *type)
{
    *format = 0;
    *type = 0;
    switch(file.dataFormat)
    {
        case GLL_DDS_RGB_8:
            *internalFormat = GL_RGB8;
            *format = GL_RGB;
            *type = GL_UNSIGNED_BYTE;
            break;
        case GLL_DDS_RGB_565:
            *internalFormat = GL_RGB8;
            *format = GL_RGB;
            *type = GL_UNSIGNED_SHORT_5_6_5;
            break;
        case GLL_DDS_ARGB_8:
            *internalFormat = GL_RGBA8;
            *format = GL_BGRA;
            *type = GL_UNSIGNED_INT_8_8_8_8_REV;
            break;
        case GLL_DDS_ABGR_8:
            *internalFormat = GL_RGBA8;
            *format = GL_RGBA;
            *type = GL_UNSIGNED_INT_8_8_8_8_REV;
            break;
        case GLL_DDS_ARGB_4:
            *internalFormat = GL_RGBA8;
            *format = GL_BGRA;
            *type = GL_UNSIGNED_SHORT_4_4_4_4_REV;
            break;
        case GLL_DDS_ARGB_1555:
            *internalFormat = GL_RGBA8;
            *format = GL_BGRA;
            *type = GL_UNSIGNED_SHORT_1_5_5_5_REV;
            break;
        case GLL_DDS_BGRX_8:
            *internalFormat = GL_RGB8;
            *format = GL_BGRA;
            *type = GL_UNSIGNED_BYTE;
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
        GLenum internalFormat;
        GLenum format;
        GLenum type;
        _dds_get_texture_format(file, &internalFormat, &format, &type);
        if (format == 0 || type == 0)
            return 0;
        glTexImage2D(GL_TEXTURE_2D, (GLsizei) mipmapLevel, internalFormat, (GLsizei) width, (GLsizei) height, 0, format, type, byteData);
    }
    
    return 1;
}

static int numMipmapLevels(long width, long height) {
    long widerDimension = MAX(width, height);
    int firstBit = flsl(widerDimension); // Computes floor(log2(x)). We want ceil(log2(x))
    int numberOfLevels = firstBit;
    if ((widerDimension & ~(1 << firstBit)) == 0)
        return firstBit - 1;
    return numberOfLevels;
}

static NSOperationQueue *imageInformationQueue = nil;

@interface GLLTexture ()

- (BOOL)_loadDDSTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error;
- (void)_loadCGCompatibleTexture:(NSData *)data error:(NSError *__autoreleasing*)error;
- (void)_loadPDFTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error;
- (void)_loadAndFreePremultipliedRGBAData:(void *)data;
- (void)_loadDefaultTexture;

- (BOOL)_loadDataError:(NSError *__autoreleasing*)error;

- (void)_setupGCDObserving;
- (void)_updateAnisotropy;

@property (nonatomic, assign, readwrite) NSUInteger width;
@property (nonatomic, assign, readwrite) NSUInteger height;

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
    
    [self _setupGCDObserving];
    
    glGenTextures(1, &_textureID);
    
    BOOL success = [self _loadDataError:error];
    if (!success) return nil;
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:GLLPrefAnisotropyAmount] options:NSKeyValueObservingOptionNew context:0];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:GLLPrefUseAnisotropy] options:NSKeyValueObservingOptionNew context:0];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self _updateAnisotropy];
}

- (void)unload;
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:GLLPrefAnisotropyAmount]];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:GLLPrefUseAnisotropy]];
    
    glDeleteTextures(1, &_textureID);
    _textureID = 0;
    self.url = nil;
}

- (void)dealloc
{
    NSAssert(_textureID == 0, @"did not call unload before dealloc");
}

- (void)_setupGCDObserving;
{
    // Inspired by http://www.davidhamrick.com/2011/10/13/Monitoring-Files-With-GCD-Being-Edited-With-A-Text-Editor.html because Photoshop follows the same annoying pattern.
    int fileHandle = open(self.url.path.fileSystemRepresentation, O_EVTONLY);
    
    __block __weak id weakSelf = self;
    __block dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fileHandle, DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^(){
        __strong id self = weakSelf;
        if (dispatch_source_get_data(source))
        {
            dispatch_source_cancel(source);
            [self _setupGCDObserving];
        }
        [self _loadDataError:NULL];
    });
    dispatch_source_set_cancel_handler(source, ^(){
        close(fileHandle);
    });
    dispatch_resume(source);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        glBindTexture(GL_TEXTURE_2D, self->_textureID);
        [self _loadDefaultTexture];
        [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
    });
    
    completionHandler(nil);
}

- (void)presentedItemDidChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL success = [self _loadDataError:NULL];
        if (!success)
        {
            // Load default
            glBindTexture(GL_TEXTURE_2D, self->_textureID);
            [self _loadDefaultTexture];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
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
        
        if (!newURL)
        {
            [self _loadDefaultTexture];
            return;
        }
        
        GLLBeginTiming("texture");
        NSData *data = [NSData dataWithContentsOfURL:newURL options:0 error:&internalError];
        
        // Ensure that memcmp does not error out.
        if (data.length < 4) return;
        
        // Load texture
        glBindTexture(GL_TEXTURE_2D, self->_textureID);
        
        if (memcmp(data.bytes, "DDS ", 4) == 0)
            [self _loadDDSTextureWithData:data error:&internalError];
        else
            [self _loadCGCompatibleTexture:data error:&internalError];
        
        if (internalError != nil) NSLog(@"Error loading texture %@: %@", self.url, internalError);
        
        GLLEndTiming("texture");
        [[NSNotificationCenter defaultCenter] postNotificationName:GLLTextureChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
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
    
    self.height = file.height;
    self.width = file.width;
    
    int numberOfLevels = numMipmapLevels(file.width, file.height);
    if (mipmap < (NSUInteger) numberOfLevels) {
        // Generate missing mipmap levels
        // A DDS file is not required to have all of them. Since I can't decode S3TC and/or reencode it, generating these mipmap levels manually is not an option, so OpenGL has to do this.
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, (GLint) (mipmap - 1));
        glGenerateMipmap(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
    }
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4.0f);
    
    return YES;
}
- (void)_loadCGCompatibleTexture:(NSData *)data error:(NSError *__autoreleasing*)error;
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    CGImageSourceStatus status = CGImageSourceGetStatus(source);
    NSString *errorStringFormat = nil;
    switch (status) {
        case kCGImageStatusUnexpectedEOF:
        case kCGImageStatusReadingHeader:
        case kCGImageStatusIncomplete:
            errorStringFormat = NSLocalizedString(@"Texture file %@ could not be loaded due to unexpected file.", @"texture status unexpectedEOF");
            break;
        case kCGImageStatusInvalidData:
            errorStringFormat = NSLocalizedString(@"Texture file %@ could not be loaded because the data is invalid.", @"texture status invalidData");
            break;
        case kCGImageStatusUnknownType:
            errorStringFormat = NSLocalizedString(@"Texture file %@ could not be loaded because the type is not supported.", @"texture status unknownType");
            break;
        case kCGImageStatusComplete:
            // All good
            break;
    }
    if (errorStringFormat) {
        if (error)
            *error = [NSError errorWithDomain:@"Textures" code:13 userInfo:@{
                                                                            NSLocalizedDescriptionKey : [NSString stringWithFormat:errorStringFormat, self.url.lastPathComponent]
                                                                            }];
        [self _loadDefaultTexture];
        CFRelease(source);
        return;
    }
    
    if (CFStringCompare(CGImageSourceGetType(source), kUTTypePDF, 0) == kCFCompareEqualTo) {
        [self _loadPDFTextureWithData:data error:error];
        CFRelease(source);
        return;
    }
    
    CFDictionaryRef dict = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    if (!dict) {
        if (error)
            *error = [NSError errorWithDomain:@"Textures" code:13 userInfo:@{
                                                                             NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Texture file %@ could not be loaded because the properties could not be loaded.", @"texture status probably a PDF"), self.url.lastPathComponent]
                                                                             }];
        [self _loadDefaultTexture];
        CFRelease(source);
        return;
    }
    
    CFIndex width, height;
    CFNumberGetValue(CFDictionaryGetValue(dict, kCGImagePropertyPixelWidth), kCFNumberCFIndexType, &width);
    CFNumberGetValue(CFDictionaryGetValue(dict, kCGImagePropertyPixelHeight), kCFNumberCFIndexType, &height);
    CFRelease(dict);
    
    self.height = height;
    self.width = width;
    
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
    
    [self _loadAndFreePremultipliedRGBAData:bufferData];
}

// Just for fun
- (void)_loadPDFTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error {
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef) data);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(dataProvider);
    
    if (!document) {
        if (*error)
            *error = [NSError errorWithDomain:@"Texture" code:14 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"PDF Texture file %@ could not be loaded.", @"texture status pdf not loaded"), self.url.lastPathComponent] }];
        [self _loadDefaultTexture];
        return;
    }
    
    size_t numberOfPages = CGPDFDocumentGetNumberOfPages(document);
    if (numberOfPages == 0) {
        if (*error)
            *error = [NSError errorWithDomain:@"Texture" code:14 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"PDF Texture file %@ has no pages.", @"texture status pdf no pages"), self.url.lastPathComponent] }];
        [self _loadDefaultTexture];
        CGPDFDocumentRelease(document);
        return;
    }
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
    if (!page) {
        if (*error)
            *error = [NSError errorWithDomain:@"Texture" code:14 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Could not load first page of PDF file %@.", @"texture status pdf no pages"), self.url.lastPathComponent] }];
        [self _loadDefaultTexture];
        CGPDFDocumentRelease(document);
        return;
    }
    
    CGRect boxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    NSLog(@"x = %f, y = %f", boxRect.size.width, boxRect.size.height);
    
    // TODO Should go via actual resolution, as far as it is specified in the
    // PDF; and maybe limit max size, too.
    self.height = (NSUInteger) (boxRect.size.width);
    self.width = (NSUInteger) (boxRect.size.height);
    
    unsigned char *bufferData = calloc(self.width * self.height, 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(bufferData, self.width, self.height, 8, self.width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
    NSAssert(cgContext != NULL, @"Could not create CG Context");
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawPDFPage(cgContext, page);
    CGContextRelease(cgContext);
    CGPDFDocumentRelease(document);
    
    [self _loadAndFreePremultipliedRGBAData:bufferData];
}

- (void)_loadAndFreePremultipliedRGBAData:(void *)bufferData; {
    // Unpremultiply the texture data. I wish I could get it unpremultiplied from the start, but CGImage doesn't allow that. Just using premultiplied sounds swell, but it messes up my blending in OpenGL.
    unsigned char *unpremultipliedBufferData = calloc(self.width * self.height, 4);
    vImage_Buffer input = { .height = self.height, .width = self.width, .rowBytes = 4*self.width, .data = bufferData };
    vImage_Buffer output = { .height = self.height, .width = self.width, .rowBytes = 4*self.width, .data = unpremultipliedBufferData };
    vImageUnpremultiplyData_ARGB8888(&input, &output, 0);
    free(bufferData);
    
    int numberOfLevels = numMipmapLevels(self.width, self.height);
    
    glTexStorage2D(GL_TEXTURE_2D, (GLsizei) numberOfLevels, GL_RGBA8, (GLsizei) self.width, (GLsizei) self.height);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei) self.width, (GLsizei) self.height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, unpremultipliedBufferData);
    
    // Load mipmaps
    vImage_Buffer lastBuffer = output;
    uint8_t *tempBuffer = NULL;
    size_t tempBufferSize = 0;
    for (int i = 1; i < numberOfLevels; i++) {
        vImage_Buffer smallerBuffer;
        smallerBuffer.width = MAX(self.width >> i, 1UL);
        smallerBuffer.height = MAX(self.height >> i, 1UL);
        smallerBuffer.rowBytes = smallerBuffer.width * 4;
        smallerBuffer.data = calloc(smallerBuffer.height * smallerBuffer.width, 4);
        
        size_t newTempSize = vImageScale_ARGB8888(&lastBuffer, &smallerBuffer, 0, kvImageGetTempBufferSize);
        if (newTempSize > tempBufferSize) {
            tempBufferSize = newTempSize;
            free(tempBuffer);
            tempBuffer = malloc(newTempSize);
        }
        
        vImageScale_ARGB8888(&lastBuffer, &smallerBuffer, tempBuffer, kvImageEdgeExtend);
        glTexSubImage2D(GL_TEXTURE_2D, i, 0, 0, (GLsizei) smallerBuffer.width, (GLsizei) smallerBuffer.height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, smallerBuffer.data);
        free(lastBuffer.data);
        lastBuffer = smallerBuffer;
    }
    free(tempBuffer);
    free(lastBuffer.data);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    [self _updateAnisotropy];
}

- (void)_loadDefaultTexture;
{
    const uint8_t defaultTexture[16] = {
        255, 255, 255, 0,
        255, 0, 0, 0,
        255, 0, 0, 0,
        255, 255, 255, 0
    };
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, 2, 2);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 2, 2, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, defaultTexture);
    
    self.width = 2;
    self.height = 2;
}

- (void)_updateAnisotropy;
{
    glBindTexture(GL_TEXTURE_2D, _textureID);
    BOOL useAnisotropy = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefUseAnisotropy];
    NSInteger anisotropyAmount = [[NSUserDefaults standardUserDefaults] integerForKey:GLLPrefAnisotropyAmount];
    if (useAnisotropy)
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropyAmount);
    else
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1.0f);
    [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
}

@end
