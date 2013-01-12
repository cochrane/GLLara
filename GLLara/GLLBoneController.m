//
//  GLLBoneController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLBoneController.h"

#import "GLLItemBone.h"

@interface GLLBoneController ()

- (void)_updateObservers;

@end

@implementation GLLBoneController

- (void)setBone:(GLLItemBone *)bone
{
	[_bone removeObserver:self forKeyPath:@"rotationX"];
	[_bone removeObserver:self forKeyPath:@"rotationY"];
	[_bone removeObserver:self forKeyPath:@"rotationZ"];
	[_bone removeObserver:self forKeyPath:@"locationX"];
	[_bone removeObserver:self forKeyPath:@"locationY"];
	[_bone removeObserver:self forKeyPath:@"locationZ"];
	
	_bone = bone;
	
	[_bone addObserver:self forKeyPath:@"rotationX" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"rotationY" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"rotationZ" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"locationX" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"locationY" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"locationZ" options:0 context:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"rotationX"] || [keyPath isEqual:@"rotationY"] || [keyPath isEqual:@"rotationZ"] || [keyPath isEqual:@"locationX"] || [keyPath isEqual:@"locationY"] || [keyPath isEqual:@"locationZ"])
	{
		[self _updateObservers];
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)addBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
{
	
}
- (void)removeBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
{
	
}

#pragma mark - Bone Change Listener

- (void)boneDidChange:(GLLBoneController *)controller
{
	[self _updateObservers];
}

#pragma mark - Private methods

- (void)_updateObservers
{
	
}

@end
