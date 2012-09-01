//
//  GLLModel.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @abstract A renderable object.
 * @discussion A GLLModel corresponds to one mesh file (which actually contains many meshes; this is a bit confusing) and describes its graphics contexts. It contains some default transformations, but does not store poses and the like.
 */
@interface GLLModel : NSObject

- (id)initWithData:(NSData *)data;

@property (nonatomic, assign, readonly) BOOL hasBones;

@property (nonatomic, copy, readonly) NSArray *bones;
@property (nonatomic, copy, readonly) NSArray *meshes;

@end
