//
//  TR1OutDataStream.h
//  TR Poser
//
//  Created by Torsten Kammer on 13.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TROutDataStream : NSObject

- (void)appendUint32:(uint32_t)value;
- (void)appendUint16:(uint16_t)value;
- (void)appendUint8:(uint8_t)value;
- (void)appendFloat32:(Float32)value;
- (void)appendInt32:(int32_t)value;
- (void)appendInt16:(int16_t)value;
- (void)appendInt8:(int8_t)value;

- (void)appendUint32Array:(const uint32_t *)array count:(NSUInteger)count;
- (void)appendUint16Array:(const uint16_t *)array count:(NSUInteger)count;
- (void)appendUint8Array:(const uint8_t *)array count:(NSUInteger)count;
- (void)appendFloat32Array:(const Float32 *)array count:(NSUInteger)count;

- (void)appendPascalString:(NSString *)string;

- (NSData *)compressed;
- (void)appendData:(NSData *)data;
- (void)appendStream:(TROutDataStream *)stream;
- (void)appendUnusedBytes:(NSUInteger)bytes;

- (NSData *)data;
- (NSUInteger)length;

@end
