//
//  TRDataStream.h
//  TR Poser
//
//  Created by Torsten Kammer on 13.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRInDataStream : NSObject

- (id)initWithData:(NSData *)data;

- (uint32_t)readUint32;
- (uint16_t)readUint16;
- (uint8_t)readUint8;
- (Float32)readFloat32;
- (int32_t)readInt32;
- (int16_t)readInt16;
- (int8_t)readInt8;

- (void)readUint32Array:(uint32_t *)array count:(NSUInteger)count;
- (void)readUint16Array:(uint16_t *)array count:(NSUInteger)count;
- (void)readUint8Array:(uint8_t *)array count:(NSUInteger)count;
- (void)readFloat32Array:(Float32 *)array count:(NSUInteger)count;

- (NSString *)readPascalString;

- (void)skipBytes:(NSUInteger)count;
- (void)skipField16:(NSUInteger)elementWidth;
- (void)skipField32:(NSUInteger)elementWidth;

- (TRInDataStream *)decompressStreamCompressedLength:(NSUInteger)actualBytes uncompressedLength:(NSUInteger)originalBytes;
- (TRInDataStream *)substreamWithLength:(NSUInteger)bytes;
- (NSData *)dataWithLength:(NSUInteger)bytes;

@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, copy, readonly) NSData *levelData;
@property (nonatomic, assign, readonly) BOOL isAtEnd;

@end
