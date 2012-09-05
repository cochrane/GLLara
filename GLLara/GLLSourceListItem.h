//
//  GLLSourceListItem.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLLSourceListItem <NSObject>

@required

@property (nonatomic, assign, readonly) BOOL isSourceListHeader;
@property (nonatomic, copy, readonly) NSString *sourceListDisplayName;
@property (nonatomic, assign, readonly) BOOL hasChildrenInSourceList;
@property (nonatomic, assign, readonly) NSUInteger numberOfChildrenInSourceList;
- (id)childInSourceListAtIndex:(NSUInteger)index;

@end
