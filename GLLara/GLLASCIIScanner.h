//
//  GLLASCIIScanner.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLLASCIIScanner : NSObject

- (id)initWithString:(NSString *)string;

- (uint32_t)readUint32;
- (uint16_t)readUint16;
- (uint8_t)readUint8;
- (Float32)readFloat32;

- (NSString *)readPascalString;

@property (nonatomic, readonly) BOOL isValid;

@end
