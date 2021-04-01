//
//  GLLModelDrawData.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLMeshDrawData;
@class GLLModel;
@class GLLResourceManager;

/*!
 * @abstract All the parts needed to draw a model.
 * @discussion The GLLModelDrawer contains everything that is needed to draw a model. In practice, that means it has a reference to the model, and otherwise just acts as a dumb container for the mesh drawers, which are the things that actually include all the data needed to draw a model.
 *
 * The GLLModelDrawer does not have a draw or render method, because it is per model, not per item. This means it has no rerence to transformations and so on. The GLLItemDrawer has all that and a render method.
 */
@interface GLLModelDrawData : NSObject

- (id)initWithModel:(GLLModel *)model resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;

@property (nonatomic, retain, readonly) GLLModel *model;
@property (nonatomic, weak, readonly) GLLResourceManager *resourceManager;
@property (nonatomic, retain, readonly) NSArray<GLLMeshDrawData *> *meshDatas;

- (void)unload;

@end
