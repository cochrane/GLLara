//
//  GLLFloatRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLFloatRenderParameter.h"


@implementation GLLFloatRenderParameter

+ (NSSet *)keyPathsForValuesAffectingUniformValue
{
    return [NSSet setWithObject:@"value"];
}

@dynamic value;

- (NSData *)uniformValue;
{
    float value = self.value;
    return [NSData dataWithBytes:&value length:sizeof(value)];
}

@end
