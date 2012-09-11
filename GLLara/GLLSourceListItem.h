//
//  GLLSourceListItem.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * @abstract A protocol to simplify dealing with the source list.
 * @discussion The source list in this app (like any good source list) includes a lot of very different elements, something that apparently did not occur to Apple. This protocol ensures that there is a standard way to build a tree and navigate through it. It is implemented by model objects that need to be shown in the source list; which is arguably a layering violation, but what can you do?
 */
@protocol GLLSourceListItem <NSObject>

@required

@property (nonatomic, assign, readonly) BOOL isSourceListHeader;
@property (nonatomic, copy, readonly) NSString *sourceListDisplayName;
@property (nonatomic, assign, readonly) BOOL hasChildrenInSourceList;
@property (nonatomic, assign, readonly) NSUInteger numberOfChildrenInSourceList;
- (id)childInSourceListAtIndex:(NSUInteger)index;

@end
