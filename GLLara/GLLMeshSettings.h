//
//  GLLMeshSettings.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "GLLSourceListItem.h"

@class GLLItem;
@class GLLMesh;

@interface GLLMeshSettings : NSManagedObject <GLLSourceListItem>

// Core data
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) GLLItem *item;

// Derived
@property (nonatomic, readonly) NSUInteger meshIndex;
@property (nonatomic, retain, readonly) GLLMesh *mesh;
@property (nonatomic, readonly, copy) NSString *displayName;

@end
