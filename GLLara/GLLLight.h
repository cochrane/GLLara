//
//  GLLLight.h
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "GLLSourceListItem.h"
#import "simd_types.h"

struct GLLLightUniformBlock
{
	vec_float4 color;
	vec_float4 direction;
	float intensity;
	float shadowDepth;
};

@interface GLLLight : NSManagedObject <GLLSourceListItem>

@property (nonatomic) BOOL isEnabled;
@property (nonatomic) NSUInteger index;
@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic, retain) NSColor *color;
@property (nonatomic) float intensity;
@property (nonatomic) float shadowDepth;

@property (nonatomic, readonly) NSData *dataAsUniformBlock;

@end
