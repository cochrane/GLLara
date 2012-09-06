//
//  GLLScene.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLSceneDelegate.h"

@interface GLLScene : NSObject

@property (nonatomic, retain, readonly) NSMutableArray *items;

// Delegates are stored as weak references
- (void)addDelegate:(id<GLLSceneDelegate>)delegate;
- (void)removeDelegate:(id<GLLSceneDelegate>)delegate;

// Used by parts of the scene. It calls all the delegates and tells them that the scene has changed and needs to be redrawn.
- (void)updateDelegates;

@end
