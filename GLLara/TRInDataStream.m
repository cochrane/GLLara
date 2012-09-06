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
	NSAssert(!self.isAtEnd, @"Cannot read from data %@ after end", self);
	NSAssert(_position + count <= _levelData.length, @"Range (%lu, %lu) is beyond end of data (length %lu)", _position, _position + count, _levelData.length);
	
	[_levelData getBytes:array range:NSMakeRange(_position, count)];
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
	
	uint8_t buffer[length];
	[self readUint8Array:buffer count:length];
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

- (TRInDataStream *)decompressStreamCompressedLength:(NSUInteger)actualBytes uncompressedLength:(NSUInteger)originalBytes;
{
	uint8_t *uncompressedData = malloc(originalBytes);
	uint8_t *compressedData = malloc(actualBytes);
	[self readUint8Array:compressedData count:actualBytes];
	
	NSUInteger uncompressedLength = originalBytes;
	
	int result = uncompress(uncompressedData, (uLongf *) &uncompressedLength, compressedData, actualBytes);
	if (result != Z_OK) [NSException raise:NSInternalInconsistencyException format:@"ZLib encountered error %i", result];
	
	if (uncompressedLength < originalBytes) [NSException raise:NSInternalInconsistencyException format:@"Not all data could be decompressed, only uncompressed %lu bytes", uncompressedLength];
	
	NSData *data = [NSData dataWithBytes:uncompressedData length:originalBytes];
	id resultLevelData = [[[self class] alloc] initWithData:data];
	
	free(compressedData);
	free(uncompressedData);
	
	return resultLevelData;
}
- (TRInDataStream *)substreamWithLength:(NSUInteger)count;
{
	NSAssert(!self.isAtEnd, @"Cannot read from data %@ after end", self);
	NSAssert(_position + count <= _levelData.length, @"Range (%lu, %lu) is beyond end of data (length %lu)", _position, _position + count, _levelData.length);
	
	NSData *underlyingData = [_levelData subdataWithRange:NSMakeRange(_position, count)];
	TRInDataStream *result = [[[self class] alloc] initWithData:underlyingData];
	_position += count;
	return result;
}

- (NSData *)dataWithLength:(NSUInteger)count
{
	NSAssert(!self.isAtEnd, @"Cannot read from data %@ after end", self);
	NSAssert(_position + count <= _levelData.length, @"Range (%lu, %lu) is beyond end of data (length %lu)", _position, _position + count, _levelData.length);

	NSData *underlyingData = [_levelData subdataWithRange:NSMakeRange(_position, count)];
	_position += count;
	
	return underlyingData;
}

- (BOOL)isAtEnd;
{
	return _position >= _levelData.length;
}

@end
