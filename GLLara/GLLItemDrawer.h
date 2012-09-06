//
//  GLLItemDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLItem;
@class GLLSceneDrawer;

/*!
 * @abstract Draw a posed instance of a model.
 * @discussion The GLLItemDrawer handles the transformations, applies them to the meshes, and tells the meshes to draw themselves (if they are visible). 
 */
@interface GLLItemDrawer : NSObject

- (id)initWithItem:(GLLItem *)item sceneDrawer:(GLLSceneDrawer *)sceneDrawer;

@property (nonatomic, retain, readonly) GLLItem *item;
@property (nonatomic, weak, readonly) GLLSceneDrawer *sceneDrawer;

- (void)drawNormal;
- (void)drawAlpha;

@end
