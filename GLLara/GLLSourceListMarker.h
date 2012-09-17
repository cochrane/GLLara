//
//  GLLSourceListMarker.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLSourceListItem.h"

/*!
 * A generic implementation of SourceListItem to be used as a default marker in various places.
 */
@interface GLLSourceListMarker : NSObject <GLLSourceListItem>

- (id)initWithObject:(id)representedObject childrenKeyPath:(NSString *)keyPath;

@property (nonatomic, copy) NSString *sourceListDisplayName;
@property (nonatomic) BOOL isSourceListHeader;

@property (nonatomic) id representedObject;
@property (nonatomic) NSString *childrenKeyPath;

@end
