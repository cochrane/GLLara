//
//  GLLDDSFile.h
//  GLLara
//
//  Created by Torsten Kammer on 28.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

enum GLLDDSDataFormat
{
	GLL_DDS_UNKNOWN,
	GLL_DDS_DXT1,
	GLL_DDS_DXT3,
	GLL_DDS_DXT5,
	GLL_DDS_ARGB_1555,
	GLL_DDS_ARGB_4,
	GLL_DDS_RGB_565,
	GLL_DDS_RGB_8,
	GLL_DDS_ARGB_8,
	GLL_DDS_XRGB_8
};

@interface GLLDDSFile : NSObject

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error;
- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing*)error;

@property (readonly, nonatomic) NSUInteger width;
@property (readonly, nonatomic) NSUInteger height;
@property (readonly, nonatomic) BOOL hasMipmaps;
@property (readonly, nonatomic) NSUInteger numMipmaps;
@property (readonly, nonatomic) BOOL isCompressed;
@property (readonly, nonatomic) enum GLLDDSDataFormat dataFormat;

- (NSData *)dataForMipmapLevel:(NSUInteger)level;

@end
