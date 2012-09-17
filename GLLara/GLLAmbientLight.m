//
//  GLLAmbientLight.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLAmbientLight.h"


@implementation GLLAmbientLight

@dynamic color;
@dynamic index;

#pragma mark - Source list item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return NSLocalizedString(@"Ambient", @"source list: ambient light name");
}
- (BOOL)isLeafInSourceList
{
	return YES;
}
- (NSUInteger)countOfSourceListChildren
{
	return 0;
}
- (id)objectInSourceListChildrenAtIndex:(NSUInteger)index;
{
	return nil;
}


@end
