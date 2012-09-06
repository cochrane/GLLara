//
//  GLLSceneDelegate.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLScene;

@protocol GLLSceneDelegate <NSObject>

- (void)sceneDidChange:(GLLScene *)scene;

@end
