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
@class GLLRenderParameter;

@interface GLLMeshSettings : NSManagedObject <GLLSourceListItem>

// Core data
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) GLLItem *item;
@property (nonatomic) int16_t cullFaceMode;
@property (nonatomic, retain) NSSet *renderParameters;

// Derived
@property (nonatomic, readonly) NSUInteger meshIndex;
@property (nonatomic, retain, readonly) GLLMesh *mesh;
@property (nonatomic, readonly, copy) NSString *displayName;

// This key is just for observing. Don't try to actually read it.
@property (nonatomic, retain) id renderSettings;

@end

@interface GLLMeshSettings (CoreDataGeneratedAccessors)

- (void)addRenderParametersObject:(GLLRenderParameter *)value;
- (void)removeRenderParametersObject:(GLLRenderParameter *)value;
- (void)addRenderParameters:(NSSet *)values;
- (void)removeRenderParameters:(NSSet *)values;

@end
