//
//  GLLDataReader.h
//  GLLara
//
//  Created by Torsten Kammer on 19.02.23.
//  Copyright © 2023 Torsten Kammer. All rights reserved.
//

#ifndef GLLDataReader_h
#define GLLDataReader_h

#import <Foundation/Foundation.h>

@protocol GLLDataReader <NSObject>

- (uint32_t)readUint32;
- (uint16_t)readUint16;
- (uint8_t)readUint8;
- (Float32)readFloat32;

- (NSString *)readPascalString;

@property (nonatomic, readonly) BOOL isValid;

@end

#endif /* GLLDataReader_h */
