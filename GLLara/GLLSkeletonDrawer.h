//
//  GLLSkeletonDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>

@class GLLItem;
@class GLLResourceManager;

@interface GLLSkeletonDrawer : NSObject

- (id)initWithResourceManager:(GLLResourceManager *)resourceManager;

- (void)unload;

- (void)draw;

@property (nonatomic) id items;
@property (nonatomic) id selectedBones;

@property (nonatomic) NSColor *defaultColor;
@property (nonatomic) NSColor *selectedColor;
@property (nonatomic) NSColor *childOfSelectedColor;

@end
