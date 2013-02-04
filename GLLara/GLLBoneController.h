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

/*!
 * @abstract Source list controller for a bone.
 * @discussion Can also be used to observe a bone, which is currently unused.
 * Gets its children from the parent bone list controller. If it came from a
 * child item, the name is altered to reflect this.
 */
@interface GLLBoneController : NSObject <GLLBoneChangeListener, NSOutlineViewDataSource>

- (id)initWithBone:(GLLItemBone *)bone listController:(GLLBoneListController *)listController;

@property (nonatomic, weak) GLLBoneListController *listController;
@property (nonatomic) GLLItemBone *bone;
@property (nonatomic, readonly) id representedObject;
@property (nonatomic, weak, readonly) id parentController;

- (void)addBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
- (void)removeBoneChangeObserver:(id <GLLBoneChangeListener>)observer;

@end
