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

@interface GLLSceneDrawer : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context view:(GLLView *)view;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) GLLResourceManager *resourceManager;
@property (nonatomic, weak, readonly) GLLView *view;

- (void)draw;

// Basic support for render to file
// bpp can be 8, for normal 24-bit rendering, or 32, which returns float pixels. The depth buffer is always 24 bit deep.
- (void)renderImageOfSize:(CGSize)size floatComponents:(BOOL)useFloatComponents multisampling:(NSUInteger)samples toColorBuffer:(void *)colorData;

@end
