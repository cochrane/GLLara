//
//  TRDataStream.m
//  TR Poser
//
//  Created by Torsten Kammer on 13.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "TRInDataStream.h"

#import <zlib.h>

@interface TRInDataStream ()

@property (nonatomic, copy, readwrite) NSData *levelData;

@end

@implementation TRInDataStream

- (id)initWithData:(NSData *)data;
{
    if (!(self = [super init])) return nil;
    
    assert(data != nil);
    
    _levelData = data;
    _position = 0;
    
    return self;
}

- (uint32_t)readUint32;
{
    uint32_t result = 0;
    [self readUint32Array:&result count:1];
    return result;
}
- (uint16_t)readUint16;
{
    uint16_t result = 0;
    [self readUint16Array:&result count:1];
    return result;
}
- (uint8_t)readUint8;
{
    uint8_t result = 0;
    [self readUint8Array:&result count:1];
    return result;
}
- (Float32)readFloat32;
{
    Float32 result = 0.0f;
    [self readFloat32Array:&result count:1];
    return result;
}
- (int32_t)readInt32;
{
    int32_t result = 0;
    [self readUint32Array:(uint32_t *) &result count:1];
    return result;
}

- (int16_t)readInt16;
{
    int16_t result = 0;
    [self readUint16Array:(uint16_t *) &result count:1];
    return result;
}

- (int8_t)readInt8;
{
    int8_t result = 0;
    [self readUint8Array:(uint8_t *) &result count:1];
    return result;
}

- (void)readUint32Array:(uint32_t *)array count:(NSUInteger)count;
{
    [self readUint8Array:(uint8_t *)array count:4*count];
}

- (void)readUint16Array:(uint16_t *)array count:(NSUInteger)count;
{
    [self readUint8Array:(uint8_t *)array count:2*count];
}

- (void)readUint8Array:(uint8_t *)array count:(NSUInteger)count;
{
    if (self.isValid && _position + count <= self.levelData.length)
        [_levelData getBytes:array range:NSMakeRange(_position, count)];
    else
        bzero(array, count);
    
    _position += count;
}

- (void)readFloat32Array:(Float32 *)array count:(NSUInteger)count;
{
    uint32_t *uint32array = (uint32_t *) array;
    [self readUint32Array:uint32array count:count];
}

- (NSString *)readPascalString;
{
    NSUInteger length = 0;
    uint8_t lengthByte = 0;
    NSUInteger shiftAmount = 0;
    do {
        lengthByte = [self readUint8];
        length += (lengthByte & 0x7F) << (7*shiftAmount);
        shiftAmount += 1;
    } while (lengthByte & 0x80);
    if (!self.isValid) return nil;
    if (length == 0) return @"";
    
    uint8_t buffer[length];
    [self readUint8Array:buffer count:length];
    if (!self.isValid) return nil;
    return [[NSString alloc] initWithBytes:buffer length:length encoding:NSUTF8StringEncoding];
}

- (void)skipBytes:(NSUInteger)count;
{
    _position += count;
}
- (void)skipField16:(NSUInteger)elementWidth;
{
    NSUInteger fieldLength = (NSUInteger) [self readUint16];
    
    [self skipBytes:fieldLength * elementWidth];
}
- (void)skipField32:(NSUInteger)elementWidth;
{
    NSUInteger fieldLength = (NSUInteger) [self readUint32];
    
    [self skipBytes:fieldLength * elementWidth];
}

- (TRInDataStream *)decompressStreamCompressedLength:(NSUInteger)actualBytes uncompressedLength:(NSUInteger)originalBytes error:(NSError *__autoreleasing*)error;
{
    if (!self.isValid) return nil;
    if (_position + actualBytes> _levelData.length)
    {
        _position += actualBytes;
        return nil;
    }
    
    uint8_t *uncompressedData = malloc(originalBytes);
    uint8_t *compressedData = malloc(actualBytes);
    [self readUint8Array:compressedData count:actualBytes];
    
    NSUInteger uncompressedLength = originalBytes;
    
    int result = uncompress(uncompressedData, (uLongf *) &uncompressedLength, compressedData, actualBytes);
    free(compressedData);
    if (result != Z_OK)
    {
        if (error)
            *error = [NSError errorWithDomain:@"TRInDataStream" code:result userInfo:@{
                                                                                       NSLocalizedDescriptionKey : NSLocalizedString(@"Could not decompress part of the data.", @"uncompress failed"),
                                                                                       NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The compressed parts of the file could not be processed. The file may be damaged.", @"uncompress failed")
                                                                                       }];
        free(uncompressedData);
        return nil;
    }
    if (uncompressedLength < originalBytes)
    {
        if (error)
            *error = [NSError errorWithDomain:@"TRInDataStream" code:result userInfo:@{
                                                                                       NSLocalizedDescriptionKey : NSLocalizedString(@"Could not decompress part of the data.", @"uncompress failed"),
                                                                                       NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"A piece of compressed data was shorter than it should have been. The file may be damaged", @"uncompress failed")
                                                                                       }];
        free(uncompressedData);
        return nil;
    }
    
    NSData *data = [NSData dataWithBytesNoCopy:uncompressedData length:uncompressedLength freeWhenDone:YES];
    id resultLevelData = [[[self class] alloc] initWithData:data];
    
    return resultLevelData;
}
- (TRInDataStream *)substreamWithLength:(NSUInteger)count;
{
    if (count == 0) return [[TRInDataStream alloc] initWithData:[NSData data]];
    if (!self.isValid) return nil;
    
    if (_position + count > _levelData.length)
    {
        _position += count;
        return nil;
    }
    
    NSData *underlyingData = [_levelData subdataWithRange:NSMakeRange(_position, count)];
    TRInDataStream *result = [[[self class] alloc] initWithData:underlyingData];
    _position += count;
    return result;
}

- (NSData *)dataWithLength:(NSUInteger)count
{
    if (count == 0) return [NSData data];
    if (!self.isValid) return nil;
    
    NSData *underlyingData = (_position + count <= _levelData.length) ? [_levelData subdataWithRange:NSMakeRange(_position, count)] : nil;
    _position += count;
    
    return underlyingData;
}

- (BOOL)isAtEnd;
{
    return _position >= _levelData.length;
}
- (BOOL)isValid
{
    return _position <= _levelData.length;
}

@end
