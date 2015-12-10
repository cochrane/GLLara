//
//  GLLLogarithmicValueTransformer.m
//  GLLara
//
//  Created by Torsten Kammer on 16.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLLogarithmicValueTransformer.h"

@implementation GLLLogarithmicValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

- (id)reverseTransformedValue:(id)value
{
    return @(pow(10.0, [value doubleValue]));
}

- (id)transformedValue:(id)value
{
    return @(log10([value doubleValue]));
}

@end
