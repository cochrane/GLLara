//
//  GLLViewDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLView;
@class GLLSceneDrawer;

@interface GLLViewDrawer : NSObject

- (id)initWithManagedSceneDrawer:(GLLSceneDrawer *)drawer view:(GLLView *)view;

@property (nonatomic, weak, readonly) GLLView *view;
@property (nonatomic, readonly) GLLSceneDrawer *sceneDrawer;

- (void)drawShowingSelection:(BOOL)selection;

// Basic support for render to file
- (void)writeImageToURL:(NSURL *)url fileType:(NSString *)type size:(CGSize)size;
- (void)renderImageOfSize:(CGSize)size toColorBuffer:(void *)colorData;

@end
