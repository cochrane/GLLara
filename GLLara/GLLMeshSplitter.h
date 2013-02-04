//
//  GLLMeshSplitter.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @abstract Describes a subset of a mesh.
 * @discussion Some models demand that certain meshes be split. This is
 * described by this class. Each object belongs to one new sub-mesh.
 */
@interface GLLMeshSplitter : NSObject

- (id)initWithPlist:(NSDictionary *)plist;

@property (nonatomic, assign, readonly) const float *min;
@property (nonatomic, assign, readonly) const float *max;
@property (nonatomic, copy, readonly) NSString *splitPartName;

@end
