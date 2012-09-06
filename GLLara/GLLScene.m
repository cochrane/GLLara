//
//  GLLScene.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLScene.h"

@interface GLLScene ()
{
	NSHashTable *delegates;
}

@end

@implementation GLLScene

- (id)init
{
	if (!(self = [super init])) return nil;
	
	_items = [[NSMutableArray alloc] init];
	
	delegates = [NSHashTable weakObjectsHashTable];
	
	return self;
}

- (void)addDelegate:(id<GLLSceneDelegate>)delegate
{
	[delegates addObject:delegate];
}
- (void)removeDelegate:(id<GLLSceneDelegate>)delegate
{
	[delegates removeObject:delegate];
}

- (void)updateDelegates;
{
	for (id<GLLSceneDelegate> delegate in delegates)
		[delegate sceneDidChange:self];
}

@end
