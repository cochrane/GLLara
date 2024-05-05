//
//  NSColor+Color32Bit.h
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>

#import <simd/simd.h>

@interface NSColor (Color32Bit)

- (void)get128BitRGBAComponents:(float *)components;

@property (assign, readonly) vector_float4 rgbaComponents128Bit;

@end
