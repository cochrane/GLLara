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
@class GLLItemBone;
@class GLLDocument;

/*!
 * @abstract Draw all elements in a scene, regardless of camera and so on.
 * @discussion The Scene Drawer encapsulates all the drawing that is constant
 * no matter what camera and context are used. It cannot render directly.
 * Instead, it is used by one or more view drawers to handle the actual drawing.
 */
@interface GLLSceneDrawer : NSObject

- (id)initWithDocument:(GLLDocument *)document;

@property (nonatomic, weak, readonly) GLLDocument *document;
@property (nonatomic, weak, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) GLLResourceManager *resourceManager;

- (void)drawShowingSelection:(BOOL)showSelection resetState:(BOOL)reset;

- (void)setSelectedBones:(NSArray<GLLItemBone *> *)selectedBones;
- (NSArray<GLLItemBone *> *)selectedBones;

// Called by item drawers
- (void)notifyRedraw;

@end
