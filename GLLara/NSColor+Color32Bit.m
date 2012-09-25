//
//  NSColor+Color32Bit.m
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "NSColor+Color32Bit.h"

#import <Cocoa/Cocoa.h>

@implementation NSColor (Color32Bit)

- (void)get32BitRGBAComponents:(uint8_t *)components;
{
	float floatComponents[4];
	[self get128BitRGBAComponents:floatComponents];
	
	for (int i = 0; i < 4; i++)
		components[i] = (uint8_t) (floatComponents[i] * 255.0f);
}
- (void)get128BitRGBAComponents:(float *)components;
{
	NSColor *selfAsRGB = [self colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
	CGFloat r, g, b, a;
	[selfAsRGB getRed:&r green:&g blue:&b alpha:&a];
	
	components[0] = (float) r;
	components[1] = (float) g;
	components[2] = (float) b;
	components[3] = (float) a;
}

@end
