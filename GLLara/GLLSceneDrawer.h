//
//  GLLSceneDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class GLLResourceManager;
@class GLLView;

/*!
 * @abstract Draw all elements in a scene, regardless of camera and so on.
 * @discussion The Scene Drawer encapsulates all the drawing that is constant
 * no matter what camera and context are used. It cannot render directly.
 * Instead, it is used by one or more view drawers to handle the actual drawing.
 */
@interface GLLSceneDrawer : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) GLLResourceManager *resourceManager;

- (void)drawWithNewStateShowingSelection:(BOOL)showSelection;
- (void)drawShowingSelection:(BOOL)showSelection;

- (void)setSelectedBones:(NSArray *)selectedBones;
- (NSArray *)selectedBones;

@end
