//
//  GLLPoseExporter.h
//  GLLara
//
//  Created by Torsten Kammer on 31.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLItem;

/*!
 * @abstract Exports a pose for a complete item or just a few bones.
 * @discussion Since it can export a pose for only a few bones, this
 * functionality does not belong to the item.
 */
@interface GLLPoseExporter : NSObject

- (id)initWithBones:(id)bones __attribute__((nonnull(1)));
- (id)initWithItem:(GLLItem *)item __attribute__((nonnull(1)));

@property (nonatomic) BOOL skipUnused;

@property (nonatomic, readonly) NSString *poseDescription;

@end
