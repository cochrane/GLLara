//
//  GLLBone.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLModel;
@class TRInDataStream;

@interface GLLBone : NSObject

- (id)initFromStream:(TRInDataStream *)stream partOfModel:(GLLModel *)model;

@property (nonatomic, weak, readonly) GLLModel *model;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSUInteger parentIndex;
@property (nonatomic, assign, readonly) float defaultPositionX;
@property (nonatomic, assign, readonly) float defaultPositionY;
@property (nonatomic, assign, readonly) float defaultPositionZ;

/*
 * Access the bones as a tree. Right now, these methods do not
 * cache their results in any way.
 */
@property (nonatomic, retain, readonly) GLLBone *parent;
@property (nonatomic, retain, readonly) NSArray *children;

@end
