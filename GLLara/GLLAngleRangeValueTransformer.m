//
//  GLLAngleRangeValueTransformer.m
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLAngleRangeValueTransformer.h"

@implementation GLLAngleRangeValueTransformer

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
	if ([value doubleValue] < 0.0)
		return @([value doubleValue] + M_PI*2);
	else
		return value;
}

- (id)transformedValue:(id)value
{
	if ([value doubleValue] > M_PI)
		return @([value doubleValue] - M_PI*2);
	else
		return value;
}

@end
