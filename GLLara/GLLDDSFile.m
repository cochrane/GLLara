//
//  GLLDDSFile.m
//  GLLara
//
//  Created by Torsten Kammer on 28.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLDDSFile.h"

// All information about the DDS file format is taken from
// http://msdn.microsoft.com/archive/default.asp?url=/archive/en-us/directx9_c/directx/graphics/reference/ddsfilereference/ddsfileformat.asp

struct __DDSFile
{
    enum GLLDDSDataFormat format;
    CFIndex width;
    CFIndex height;
    CFIndex numMipmapLevels;
    CFDataRef data;
};

struct DDSPixelFormat
{
    uint32_t size;
    uint32_t flags;
    union {
        uint32_t fourCC;
        uint8_t fourCCString[4];
    };
    uint32_t rgbBitCount;
    uint32_t rBitMask;
    uint32_t gBitMask;
    uint32_t bBitMask;
    uint32_t aBitMask;
};

struct DDSCaps
{
    uint32_t caps1;
    uint32_t caps2;
    uint32_t reserved[2];
};

struct DDSFileHeader
{
    uint32_t size;
    uint32_t flags;
    uint32_t height;
    uint32_t width;
    uint32_t pitchOrLinearSize;
    uint32_t depth;
    uint32_t mipMapCount;
    uint32_t reserved1[11];
    struct DDSPixelFormat pixelFormat;
    struct DDSCaps caps;
    uint32_t reserved2;
};

static NSString *ddsError = @"DDS File Loading";

@interface GLLDDSFile ()
{
    NSData *fileData;
}

@end

@implementation GLLDDSFile

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error
{
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) return nil;
    
    return [self initWithData:data error:error];
}

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (!(self = [super init])) return nil;
    
    const void *fileContents = data.bytes;
    if (memcmp(fileContents, "DDS ", 4) != 0)
    {
        if (error)
            *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                         NSLocalizedDescriptionKey : NSLocalizedString(@"This DDS file is corrupt.", @"DDS: Does not start with DDS"),
                                                                         NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file cannot be opened because it has an incorrect start sequence. This usually indicates that the file is damaged or not a DDS file at all.", @"DDS: Does not start with DDS")}];
        ;
        return nil;
    }
    
    struct DDSFileHeader header;
    memcpy((void *) &header, fileContents + 4, sizeof(header));
    if (header.size != 124)
    {
        if (error)
            *error = [NSError errorWithDomain:ddsError code:2 userInfo:@{
                                                                         NSLocalizedDescriptionKey : NSLocalizedString(@"This DDS file is not supported.", @"DDS: Header size wrong"),
                                                                         NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file cannot be read because it uses a different header size than normal. This may be because it uses a newer version of the file format, or because it is damaged.", @"DDS: Header size wrong")}];
        
        return nil;
    }
    if (header.pixelFormat.size != 32)
    {
        if (error)
            *error = [NSError errorWithDomain:ddsError code:3 userInfo:@{
                                                                         NSLocalizedDescriptionKey : NSLocalizedString(@"This DDS file is not supported.", @"DDS: Pixel format size wrong"),
                                                                         NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file cannot be read because it uses a different pixel format size than normal. This may be because it uses a newer version of the file format, or because it is damaged.", @"DDS: Pixel format size wrong")}];
        
        return nil;
    }
    
    // Find the file's format
    if (header.pixelFormat.flags & 4) // Use the FourCC
    {
        if (header.pixelFormat.fourCC == NSSwapBigIntToHost('DXT1'))
            _dataFormat = GLL_DDS_DXT1;
        else if (header.pixelFormat.fourCC == NSSwapBigIntToHost('DXT3'))
            _dataFormat = GLL_DDS_DXT3;
        else if (header.pixelFormat.fourCC == NSSwapBigIntToHost('DXT5'))
            _dataFormat = GLL_DDS_DXT5;
        else
        {
            if (error)
                *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                             NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Graphics format %4s is not supported.", @"DDS: Unknown FourCC"), header.pixelFormat.fourCCString],
                                                                             NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file cannot be read because it uses a compressed data format that is not supported. Only DXT1, DXT3 and DXT5 formats are supported.", @"DDS: Unknown FourCC")}];
            
            return nil;
        }
    }
    else if (header.pixelFormat.flags & 64) // Use RGB
    {
        if (header.pixelFormat.flags & 1) // Contains alpha
        {
            if (header.pixelFormat.rgbBitCount == 32)
            {
                // To be supported, it has to be ARGB32 now.
                if (!((header.pixelFormat.aBitMask == 0xff000000) &&
                      (header.pixelFormat.rBitMask == 0x00ff0000) &&
                      (header.pixelFormat.gBitMask == 0x0000ff00) &&
                      (header.pixelFormat.bBitMask == 0x000000ff)))
                {
                    if (error)
                        *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                     NSLocalizedDescriptionKey : NSLocalizedString(@"Graphics format is not supported.", @"DDS: Unknown 32-bit alpha format"),
                                                                                     NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Only ARGB is supported for 32 bit uncompressed textures.", @"DDS: Unknown 32-bit format")}];
                    return nil;
                }
                _dataFormat = GLL_DDS_ARGB_8;
            }
            else if (header.pixelFormat.rgbBitCount == 16)
            {
                // It can be ARGB4 (what format is that? never heard of it) or ARGB1555.
                if (header.pixelFormat.aBitMask == 0x8000 && header.pixelFormat.rBitMask == 0x7C00 && header.pixelFormat.gBitMask == 0x03E0 && header.pixelFormat.bBitMask == 0x001F)
                    _dataFormat = GLL_DDS_ARGB_1555;
                else if (header.pixelFormat.aBitMask == 0xF000 && header.pixelFormat.rBitMask == 0x0F00 && header.pixelFormat.gBitMask == 0x00F0 && header.pixelFormat.bBitMask == 0x000F)
                    _dataFormat = GLL_DDS_ARGB_4;
                else
                {
                    if (error)
                        *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                     NSLocalizedDescriptionKey : NSLocalizedString(@"Graphics format is not supported.", @"DDS: Unknown 16-bit alpha format"),
                                                                                     NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Only ARGB4 and ARGB1555 are supported for 16 bit uncompressed textures with alpha channel.", @"DDS: Unknown 16-bit alpha format")}];
                    return nil;
                }
            }
            else
            {
                if (error)
                    *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                 NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"%u bits per pixel with alpha are not supported.", @"DDS: Unknown alpha bitcount"), header.pixelFormat.rgbBitCount],
                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Uncompressed formats with alpha have to be 32 or 16 bits per pixel.", @"DDS: Unknown alpha bitcount")}];
                return nil;
            }
            
        }
        else // No alpha
        {
            if (header.pixelFormat.rgbBitCount == 32)
            {
                // To be supported, it has to be ?RGB32 now.
                if (!((header.pixelFormat.rBitMask == 0x00ff0000) &&
                      (header.pixelFormat.gBitMask == 0x0000ff00) &&
                      (header.pixelFormat.bBitMask == 0x000000ff)))
                {
                    if (error)
                        *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                     NSLocalizedDescriptionKey : NSLocalizedString(@"Graphics format is not supported.", @"DDS: Unknown 32-bit alpha format"),
                                                                                     NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Only XRGB is supported for 32 bit uncompressed textures with alpha.", @"DDS: Unknown 32-bit alpha format")}];
                    return nil;
                }
                _dataFormat = GLL_DDS_BGRX_8;
            }
            else if (header.pixelFormat.rgbBitCount == 24)
            {
                // To be supported, it has to be RGB32 now.
                if (!((header.pixelFormat.rBitMask == 0x00ff0000) &&
                      (header.pixelFormat.gBitMask == 0x0000ff00) &&
                      (header.pixelFormat.bBitMask == 0x000000ff)))
                {
                    if (error)
                        *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                     NSLocalizedDescriptionKey : NSLocalizedString(@"Graphics format is not supported.", @"DDS: Unknown 24-bit non-alpha format"),
                                                                                     NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Only RGB is supported for 24 bit uncompressed textures.", @"DDS: Unknown 24-bit non-alpha format")}];
                    return nil;
                }
                _dataFormat = GLL_DDS_RGB_8;
            }
            else if (header.pixelFormat.rgbBitCount == 16)
            {
                // To be supported, it has to be RGB565 now.
                if (!((header.pixelFormat.rBitMask == 0xF800) &&
                      (header.pixelFormat.gBitMask == 0x7E0) &&
                      (header.pixelFormat.bBitMask == 0x001F)))
                {
                    if (error)
                        *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                     NSLocalizedDescriptionKey : NSLocalizedString(@"Graphics format is not supported.", @"DDS: Unknown 16-bit non-alpha format"),
                                                                                     NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Only RGB565 is supported for 16 bit uncompressed textures without alpha.", @"DDS: Unknown 16-bit non-alpha format")}];
                    return nil;
                }
                _dataFormat = GLL_DDS_RGB_565;
            }
            else
            {
                if (error)
                    *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                                 NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"%u bits per pixel without alpha are not supported.", @"DDS: Unknown non-alpha bitcount"), header.pixelFormat.rgbBitCount],
                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file uses a data layout that is not supported. Uncompressed formats without alpha have to be 32, 24 or 16 bits per pixel.", @"DDS: Unknown non-alpha bitcount")}];
                return nil;
                
            };
        }
    }
    else
    {
        if (error)
            *error = [NSError errorWithDomain:ddsError code:1 userInfo:@{
                                                                         NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The file's graphics format is not supported.", @"DDS: Unknown graphics format"), header.pixelFormat.rgbBitCount],
                                                                         NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Only DXT1,3,5 and uncompressed (A)RGB formats are supported.", @"DDS: Unknown graphics format")}];
		return nil;
    }
    
    _width = header.width;
    _height = header.height;
    _numMipmaps = header.mipMapCount;
    
    fileData = data;
    
    return self;
}

- (NSData *)dataForMipmapLevel:(NSUInteger)level;
{
    NSUInteger size = 0;
    NSUInteger offset = 0;
    NSUInteger height = self.height;
    NSUInteger width = self.width;
    NSUInteger i;
    for (i = 0; i <= level && (width || height); ++i)
    {
        if (width == 0)
            width = 1;
        if (height == 0)
            height = 1;
        
        offset += size;
        
        switch(self.dataFormat)
        {
            case GLL_DDS_DXT1:
                size = ((width+3)/4)*((height+3)/4)*8;
                break;
            case GLL_DDS_DXT3:
            case GLL_DDS_DXT5:
                size = ((width+3)/4)*((height+3)/4)*16;
                break;
            case GLL_DDS_ARGB_1555:
            case GLL_DDS_ARGB_4:
            case GLL_DDS_RGB_565:
                size = (width * height) * 2;
                break;
            case GLL_DDS_RGB_8:
                size = (width * height) * 3;
                break;
            case GLL_DDS_ARGB_8:
            case GLL_DDS_BGRX_8:
                size = (width * height) * 4;
                break;
            default:
                [NSException raise:NSInternalInconsistencyException format:@"Size for format %lu unknown", (NSUInteger) self.dataFormat];
        }
        width  >>= 1;
        height >>= 1;
    }
    if (size == 0) return NULL;
    
    NSUInteger newDataStart = 4 + sizeof(struct DDSFileHeader) + offset;
    
    if (newDataStart + size > fileData.length)
        return NULL;
    
    return [fileData subdataWithRange:NSMakeRange(newDataStart, size)];
}

- (BOOL)isCompressed
{
    return (self.dataFormat == GLL_DDS_DXT1 || self.dataFormat == GLL_DDS_DXT3 || self.dataFormat == GLL_DDS_DXT5);
}

- (BOOL)hasMipmaps
{
    return self.numMipmaps > 0;
}

@end
