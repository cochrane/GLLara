//
//  GLLASCIIScanner.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLDataReader.h"

/*!
 * @abstract Reader for the .mesh.ascii format.
 * @discussion It was deliberately designed to have the same interface as the
 * TRInDataStream. Thus, it can read integers in different widths, although
 * parsing them from an ASCII file is always the same work.
 */
@interface GLLASCIIScanner : NSObject <GLLDataReader>

- (id)initWithString:(NSString *)string;

- (uint32_t)readUint32;
- (uint16_t)readUint16;
- (uint8_t)readUint8;
- (Float32)readFloat32;

- (NSString *)readPascalString;

// Tries to scan a newline; returns whether that succeeded. If not, newlines are skipped.
- (BOOL)hasNewline;

@property (nonatomic, readonly) BOOL isValid;

@end
