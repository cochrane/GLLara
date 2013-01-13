//
//  GLLBoneListController.h
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItem;

@interface GLLBoneListController : NSObject <NSOutlineViewDataSource>

- (id)initWithItem:(GLLItem *)item;

@property (nonatomic) GLLItem *item;
@property (nonatomic, readonly) NSArray *boneControllers;

@end
