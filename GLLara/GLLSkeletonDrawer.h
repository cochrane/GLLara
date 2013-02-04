//
//  GLLSkeletonDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>

#import "GLLDrawState.h"

@class GLLItem;
@class GLLResourceManager;

/*!
 * @abstract Draws the skeleton/rig of an object, with color-coding for the
 * different parts regarding selection.
 */
@interface GLLSkeletonDrawer : NSObject

- (id)initWithResourceManager:(GLLResourceManager *)resourceManager;

- (void)unload;

- (void)drawWithState:(GLLDrawState *)state;

@property (nonatomic) id items;
@property (nonatomic) id selectedBones;

@property (nonatomic) NSColor *defaultColor;
@property (nonatomic) NSColor *selectedColor;
@property (nonatomic) NSColor *childOfSelectedColor;

@end
