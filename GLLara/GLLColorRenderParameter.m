//
//  GLLColorRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLColorRenderParameter.h"

#import <AppKit/NSColorSpace.h>

@implementation GLLColorRenderParameter

+ (NSSet *)keyPathsForValuesAffectingUniformValue
{
	return [NSSet setWithObject:@"value"];
}

@dynamic value;

- (NSData *)uniformValue;
{
	CGFloat r = 0, g = 0, b = 0, a = 0;
	if (self.value)
	[[self.value colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];

	
	float values[4] = { r, g, b, a };
	return [NSData dataWithBytes:&values length:sizeof(values)];
}

@end
