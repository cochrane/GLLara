//
//  GLLPoseExporter.h
//  GLLara
//
//  Created by Torsten Kammer on 31.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLItem;

@interface GLLPoseExporter : NSObject

- (id)initWithBones:(id)bones;
- (id)initWithItem:(GLLItem *)item;

@property (nonatomic) BOOL skipUnused;

@property (nonatomic) NSString *poseDescription;

@end
