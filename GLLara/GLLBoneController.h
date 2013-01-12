//
//  GLLBoneController.h
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLItemBone;

@class GLLBoneController;

@protocol GLLBoneChangeListener <NSObject>

- (void)boneDidChange:(GLLBoneController *)controller;

@end

@interface GLLBoneController : NSObject <GLLBoneChangeListener>

@property (nonatomic) GLLItemBone *bone;

- (void)addBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
- (void)removeBoneChangeObserver:(id <GLLBoneChangeListener>)observer;

// Derived
@property (nonatomic, readonly) GLLBoneController *parentController;

@end
