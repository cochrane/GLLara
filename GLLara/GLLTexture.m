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
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "GLLDDSFile.h"
#import "GLLNotifications.h"
#import "GLLPreferenceKeys.h"
#import "GLLTiming.h"

NSString *GLLTextureChangeNotification = @"GLL Texture Change Notification";

enum GLLTextureOrder {
    GLLTextureOrderARGB,
    GLLTextureOrderBGRA
};

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
- (BOOL)_loadCGCompatibleTexture:(NSData *)data error:(NSError *__autoreleasing*)error;
- (BOOL)_loadPDFTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error;
- (void)_loadAndFreePremultipliedARGBData:(void *)data;
- (void)_loadAndFreeUnpremultipliedData:(vImage_Buffer *)unpremultipliedBufferData order:(enum GLLTextureOrder)textureOrder;
- (void)_loadDefaultTexture;

- (BOOL)_loadDataError:(NSError *__autoreleasing*)error;
- (BOOL)_loadWithData:(NSData *)data error:(NSError *__autoreleasing*)error;

- (void)_setupGCDObserving;

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

- (id)initWithURL:(NSURL *)url device:(id<MTLDevice>)device error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(url);
    
    if (!(self = [super init])) return nil;
    
    [NSFileCoordinator addFilePresenter:self];
    
    self.device = device;
    self.url = url.absoluteURL;
    
    [self _setupGCDObserving];
    
    BOOL success = [self _loadDataError:error];
    if (!success) return nil;
        
    return self;
}

- (id)initWithData:(NSData *)data sourceURL:(NSURL*)url device:(id<MTLDevice>)device error:(NSError *__autoreleasing *)error __attribute__((nonnull(1)))
{
    NSParameterAssert(data);
    
    if (!(self = [super init])) return nil;
    
    self.device = device;
    self.url = url.absoluteURL;
    
    BOOL success = [self _loadWithData:data error:error];
    if (!success) return nil;
    
    return self;
}

- (void)unload;
{
    self.url = nil;
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
        
        if (!newURL)
        {
            [self _loadDefaultTexture];
            return;
        }
        
        GLLBeginTiming("texture");
        NSData *data = [NSData dataWithContentsOfURL:newURL options:0 error:&internalError];
        
        BOOL result = [self _loadWithData:data error:&internalError];
        if (!result) {
            NSLog(@"Error loading texture %@: %@", self.url, internalError);
        }
        
        GLLEndTiming("texture");
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

- (BOOL)_loadWithData:(NSData *)data error:(NSError *__autoreleasing*)error;
{
    // Ensure that memcmp does not error out.
    if (data.length < 4) return NO;
    
    // Load texture
    
    BOOL result = YES;
    if (memcmp(data.bytes, "DDS ", 4) == 0)
        result = [self _loadDDSTextureWithData:data error:error];
    else
        result = [self _loadCGCompatibleTexture:data error:error];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GLLTextureChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
    
    return result;
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
    
    self.height = file.height;
    self.width = file.width;
    
    // Find pixel format
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:file.width height:file.height mipmapped:file.hasMipmaps];
    
    descriptor.mipmapLevelCount = file.numMipmaps;
    
    BOOL expand24BitFormat = NO;
    switch (file.dataFormat) {
        case GLL_DDS_DXT1:
            descriptor.pixelFormat = MTLPixelFormatBC1_RGBA;
            break;
        case GLL_DDS_DXT3:
            descriptor.pixelFormat = MTLPixelFormatBC2_RGBA;
            break;
        case GLL_DDS_DXT5:
            descriptor.pixelFormat = MTLPixelFormatBC3_RGBA;
            break;
        case GLL_DDS_BGR_8:
            descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
            expand24BitFormat = YES;
        case GLL_DDS_BGRA_8:
            descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
            break;
        case GLL_DDS_RGBA_8:
            descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
            break;
        case GLL_DDS_ARGB_4:
            // TODO Does this need swizzling? Probably, right?
            descriptor.pixelFormat = MTLPixelFormatABGR4Unorm;
            MTLTextureSwizzleChannels channels = {
                .red = MTLTextureSwizzleGreen,
                .green = MTLTextureSwizzleRed,
                .blue = MTLTextureSwizzleAlpha,
                .alpha = MTLTextureSwizzleBlue,
            };
            descriptor.swizzle = channels;
            break;
        case GLL_DDS_RGB_565:
            descriptor.pixelFormat = MTLPixelFormatB5G6R5Unorm;
            break;
        case GLL_DDS_ARGB_1555:
            descriptor.pixelFormat = MTLPixelFormatBGR5A1Unorm;
            break;
        case GLL_DDS_BGRX_8:
            descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
            break;
        default:
            if (error)
                *error = [NSError errorWithDomain:@"Textures" code:12 userInfo:@{
                                                                                 NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"DDS File %@ couldn't be opened: Pixel format is not supported", @"Can't find pixel format"), self.url.lastPathComponent]
                                                                                 }];
            return NO;
    }
    
    _texture = [self.device newTextureWithDescriptor:descriptor];
    _texture.label = self.url.lastPathComponent;
    
    for (NSUInteger i = 0; i < file.numMipmaps; i++) {
        NSUInteger levelWidth = self.width >> i;
        NSUInteger levelHeight = self.width >> i;
        
        MTLRegion region = MTLRegionMake2D(0, 0, levelWidth, levelHeight);
        
        NSData *data = [file dataForMipmapLevel:i];
        if (expand24BitFormat) {
            // Metal does not support 24 bit texture formats, so we need to expand this data manually.
            // Grr
            NSUInteger pixels = levelWidth * levelHeight;
            const uint8_t *originalBytes = data.bytes;
            uint8_t *resizedData = calloc(sizeof(uint8_t [4]), pixels);
            for (NSUInteger i = 0; i < pixels; i++) {
                resizedData[i*4 + 0] = originalBytes[i*3 + 0];
                resizedData[i*4 + 1] = originalBytes[i*3 + 1];
                resizedData[i*4 + 2] = originalBytes[i*3 + 2];
                resizedData[i*4 + 3] = 0xFF;
            }
            [_texture replaceRegion:region mipmapLevel:i withBytes:resizedData bytesPerRow:levelWidth * 4];
            free(resizedData);
        } else {
            [_texture replaceRegion:region mipmapLevel:i withBytes:data.bytes bytesPerRow:data.length / levelHeight];
        }
    }
    
    return YES;
}
- (BOOL)_loadCGCompatibleTexture:(NSData *)data error:(NSError *__autoreleasing*)error;
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
        return NO;
    }
    
    NSString *sourceType = (__bridge NSString*) CGImageSourceGetType(source);
    if ([sourceType isEqual:UTTypePDF.identifier]) {
        BOOL result = [self _loadPDFTextureWithData:data error:error];
        CFRelease(source);
        return result;
    }
    
    CFDictionaryRef dict = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    if (!dict) {
        if (error)
            *error = [NSError errorWithDomain:@"Textures" code:13 userInfo:@{
                                                                             NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Texture file %@ could not be loaded because the properties could not be loaded.", @"texture status probably a PDF"), self.url.lastPathComponent]
                                                                             }];
        [self _loadDefaultTexture];
        CFRelease(source);
        return NO;
    }
    
    CFIndex width, height;
    CFNumberGetValue(CFDictionaryGetValue(dict, kCGImagePropertyPixelWidth), kCFNumberCFIndexType, &width);
    CFNumberGetValue(CFDictionaryGetValue(dict, kCGImagePropertyPixelHeight), kCFNumberCFIndexType, &height);
    CFRelease(dict);
    
    self.height = height;
    self.width = width;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    vImage_Buffer buffer = { .height = 0, .width = 0, .rowBytes = 0, .data = 0};
    vImage_CGImageFormat format = {
        .version = 0,
        .decode = 0,
        .bitsPerPixel = 32,
        .bitsPerComponent = 8,
        .bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrderDefault,
        .colorSpace = colorSpace
    };
    CGFloat backgroundColor[] = { 0, 0, 0, 0 };
    
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    
    vImage_Error result = vImageBuffer_InitWithCGImage(&buffer, &format, backgroundColor, cgImage, kvImageNoFlags);
    CGImageRelease(cgImage);
    if (result != kvImageNoError) {
        if (error)
            *error = [NSError errorWithDomain:@"Textures" code:13 userInfo:@{
                                                                             NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Texture file %@ could not be loaded because the properties could not be loaded.", @"texture status probably a PDF"), self.url.lastPathComponent]
                                                                             }];
        [self _loadDefaultTexture];
        return NO;
    }
    
    [self _loadAndFreeUnpremultipliedData:&buffer order:GLLTextureOrderARGB];
    
    return YES;
}

// Just for fun
- (BOOL)_loadPDFTextureWithData:(NSData *)data error:(NSError *__autoreleasing*)error {
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef) data);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(dataProvider);
    CGDataProviderRelease(dataProvider);
    
    if (!document) {
        if (*error)
            *error = [NSError errorWithDomain:@"Texture" code:14 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"PDF Texture file %@ could not be loaded.", @"texture status pdf not loaded"), self.url.lastPathComponent] }];
        [self _loadDefaultTexture];
        return NO;
    }
    
    size_t numberOfPages = CGPDFDocumentGetNumberOfPages(document);
    if (numberOfPages == 0) {
        if (*error)
            *error = [NSError errorWithDomain:@"Texture" code:14 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"PDF Texture file %@ has no pages.", @"texture status pdf no pages"), self.url.lastPathComponent] }];
        [self _loadDefaultTexture];
        CGPDFDocumentRelease(document);
        return NO;
    }
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
    if (!page) {
        if (*error)
            *error = [NSError errorWithDomain:@"Texture" code:14 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Could not load first page of PDF file %@.", @"texture status pdf no pages"), self.url.lastPathComponent] }];
        [self _loadDefaultTexture];
        CGPDFDocumentRelease(document);
        return NO;
    }
    
    // Find user unit, if any
    CGPDFReal userUnit = 1.0;
    CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page);
    if (pageDictionary) {
        if (!CGPDFDictionaryGetNumber(pageDictionary, "UserUnit", &userUnit))
            userUnit = 1.0;
    }
    // Unit is userUnit / 72 inch. We want 300 DPI.
    CGFloat scale = (userUnit / 72.0) * 300.0;
    
    // Limit size
    const CGFloat maxSize = 2048.0;
    CGRect boxRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    if (boxRect.size.width * scale > maxSize)
        scale = maxSize / boxRect.size.width;
    if (boxRect.size.height * scale > maxSize)
        scale = maxSize / boxRect.size.height;
    
    // TODO Should go via actual resolution, as far as it is specified in the
    // PDF; and maybe limit max size, too.
    self.height = (NSUInteger) (boxRect.size.width * scale);
    self.width = (NSUInteger) (boxRect.size.height * scale);
    
    unsigned char *bufferData = calloc(self.width * self.height, 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(bufferData, self.width, self.height, 8, self.width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
    NSAssert(cgContext != NULL, @"Could not create CG Context");
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextScaleCTM(cgContext, scale, scale);
    
    CGContextDrawPDFPage(cgContext, page);
    CGContextRelease(cgContext);
    CGPDFDocumentRelease(document);
    
    [self _loadAndFreePremultipliedARGBData:bufferData];
    return YES;
}

- (void)_loadAndFreePremultipliedARGBData:(void *)bufferData; {
    // Unpremultiply the texture data. I wish I could get it unpremultiplied from the start, but CGImage doesn't allow that. Just using premultiplied sounds swell, but it messes up my blending in OpenGL.
    unsigned char *unpremultipliedBufferData = calloc(self.width * self.height, 4);
    vImage_Buffer input = { .height = self.height, .width = self.width, .rowBytes = 4*self.width, .data = bufferData };
    vImage_Buffer output = { .height = self.height, .width = self.width, .rowBytes = 4*self.width, .data = unpremultipliedBufferData };
    vImageUnpremultiplyData_ARGB8888(&input, &output, 0);
    free(bufferData);
    
    [self _loadAndFreeUnpremultipliedData:&output order:GLLTextureOrderARGB];
}

- (void)_loadAndFreeUnpremultipliedData:(vImage_Buffer *)unpremultipliedBufferData order:(enum GLLTextureOrder)order; {
    int numberOfLevels = numMipmapLevels(self.width, self.height);
    
    MTLTextureDescriptor* descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:self.width height:self.height mipmapped:YES];
    if (order == GLLTextureOrderARGB) {
        // Metal does not support any alpha-first formats, and we need ARGB for the unpremultiply to work, so swizzle
        // A -> B
        // R -> G
        // G -> R
        // B -> A
        MTLTextureSwizzleChannels channels = {
            .alpha = MTLTextureSwizzleBlue,
            .red = MTLTextureSwizzleGreen,
            .green = MTLTextureSwizzleRed,
            .blue = MTLTextureSwizzleAlpha
        };
        descriptor.swizzle = channels;
    }
    _texture = [_device newTextureWithDescriptor:descriptor];
    _texture.label = self.url.lastPathComponent;
    
    MTLRegion region = MTLRegionMake2D(0, 0, self.width, self.height);
    [_texture replaceRegion:region mipmapLevel:0 withBytes:unpremultipliedBufferData->data bytesPerRow:unpremultipliedBufferData->rowBytes];
    
    // Load mipmaps
    vImage_Buffer lastBuffer = *unpremultipliedBufferData;
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
        free(lastBuffer.data);
        
        MTLRegion region = MTLRegionMake2D(0, 0, smallerBuffer.width, smallerBuffer.height);
        [_texture replaceRegion:region mipmapLevel:i withBytes:smallerBuffer.data bytesPerRow:smallerBuffer.rowBytes];
        
        lastBuffer = smallerBuffer;
    }
    free(tempBuffer);
    free(lastBuffer.data);
}

- (void)_loadDefaultTexture;
{
    const uint8_t defaultTexture[16] = {
        255, 255, 255, 255,
        255, 0, 0, 255,
        255, 0, 0, 255,
        255, 255, 255, 255
    };
    self.width = 2;
    self.height = 2;
    
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:self.width height:self.height mipmapped:YES];
    
    _texture = [self.device newTextureWithDescriptor:descriptor];
    _texture.label = @"default-texture";
    MTLRegion region = MTLRegionMake2D(0, 0, self.width, self.height);
    
    [self.texture replaceRegion:region mipmapLevel:0 withBytes:defaultTexture bytesPerRow:2*4];
    
    const uint8_t defaultTextureSmall[4] = {
        255, 128, 128, 255
    };
    MTLRegion regionLevel1 = MTLRegionMake2D(0, 0, 1, 1);
    [self.texture replaceRegion:regionLevel1 mipmapLevel:1 withBytes:defaultTextureSmall bytesPerRow:4];
}

@end
