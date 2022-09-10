//
//  GLLColorRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLColorRenderParameter.h"

#import "NSColor+Color32Bit.h"

@implementation GLLColorRenderParameter

+ (NSSet *)keyPathsForValuesAffectingUniformValue
{
    return [NSSet setWithObject:@"value"];
}

@dynamic value;

- (NSData *)uniformValue;
{
    float values[4] = { 0, 0, 0, 0 };
    [self.value get128BitRGBAComponents:values];
    return [NSData dataWithBytes:&values length:sizeof(values)];
}

@end
