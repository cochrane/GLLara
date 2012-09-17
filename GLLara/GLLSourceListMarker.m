//
//  GLLSourceListMarker.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSourceListMarker.h"

@interface GLLSourceListMarker ()

- (NSArray *)_getChildren;

@end

@implementation GLLSourceListMarker

- (id)initWithObject:(id)representedObject childrenKeyPath:(NSString *)keyPath;
{
	if (!(self = [super init])) return nil;
	
	self.representedObject = representedObject;
	self.childrenKeyPath = keyPath;
	
	[self.representedObject addObserver:self forKeyPath:keyPath options:0 context:0];
	
	return self;
}

- (void)dealloc
{
	[self.representedObject removeObserver:self forKeyPath:self.childrenKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:self.childrenKeyPath])
	{
		[self willChangeValueForKey:@"sourceListChildren"];
		[self didChangeValueForKey:@"sourceListChildren"];
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (BOOL)isLeafInSourceList
{
	return NO;
}
- (NSUInteger)countOfSourceListChildren
{
	return [self _getChildren].count;
}
- (id)objectInSourceListChildrenAtIndex:(NSUInteger)index;
{
	return [[self _getChildren] objectAtIndex:index];
}

- (NSArray *)_getChildren
{
	if (!self.representedObject) return nil;
	if (!self.childrenKeyPath) return nil;
	
	return [self.representedObject valueForKeyPath:self.childrenKeyPath];
}

@end
