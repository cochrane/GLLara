//
//  GLLBoneController.h
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItemBone;

@class GLLBoneController;
@class GLLBoneListController;

@protocol GLLBoneChangeListener <NSObject>

- (void)boneDidChange:(GLLBoneController *)controller;

@end

@interface GLLBoneController : NSObject <GLLBoneChangeListener, NSOutlineViewDataSource>

- (id)initWithBone:(GLLItemBone *)bone listController:(GLLBoneListController *)listController;

@property (nonatomic, weak) GLLBoneListController *listController;
@property (nonatomic) GLLItemBone *bone;
@property (nonatomic, readonly) id representedObject;

- (void)addBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
- (void)removeBoneChangeObserver:(id <GLLBoneChangeListener>)observer;

// Derived
@property (nonatomic, readonly) GLLBoneController *parentController;

@end
