
//
//  GLLItemDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLDrawState.h"

@class GLLItem;
@class GLLSceneDrawer;

/*!
 * @abstract Draw a posed instance of a model.
 * @discussion The GLLItemDrawer handles the transformations, applies them to the meshes, and tells the meshes to draw themselves (if they are visible).
 *
 * To see whether it needs drawing, observe the needsRedraw key. This is only sends notifications when changing from NO to YES, so ignore the value and simply schedule a draw.
 */
@interface GLLItemDrawer : NSObject

- (id)initWithItem:(GLLItem *)item sceneDrawer:(GLLSceneDrawer *)sceneDrawer replacedTextures:(NSDictionary<NSURL*,NSError*> *__autoreleasing*)textures error:(NSError *__autoreleasing*)error;

@property (nonatomic, retain, readonly) GLLItem *item;
@property (nonatomic, weak, readonly) GLLSceneDrawer *sceneDrawer;

- (void)propertiesChanged;

- (void)drawSolidWithState:(GLLDrawState *)state;
- (void)drawAlphaWithState:(GLLDrawState *)state;

- (void)unload;

@end
