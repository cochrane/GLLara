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

extern NSString *GLLSceneDrawerNeedsUpdateNotification;

@interface GLLSceneDrawer : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) GLLResourceManager *resourceManager;

- (void)draw;

- (void)setSelectedBones:(NSArray *)selectedBones;

@end
