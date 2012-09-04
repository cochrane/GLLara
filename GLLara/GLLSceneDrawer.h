//
//  GLLSceneDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLScene;
@class GLLResourceManager;

@interface GLLSceneDrawer : NSObject

- (id)initWithScene:(GLLScene *)scene resourceManager:(GLLResourceManager *)resourceManager;

@property (nonatomic, retain, readonly) GLLScene *scene;
@property (nonatomic, retain) GLLResourceManager *resourceManager;

- (void)setWindowSize:(NSSize)size;

- (void)draw;

@end
