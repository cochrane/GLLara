//
//  GLLItemOptionalPartMarker.h
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLItem;

/*!
 * A simple object that only contains a GLLItem; used for selection to mark that
 * the "optional parts" section was selected.
 *
 * Equality and hash code: Two of these are equal - and have equal hash codes -
 * if the underlying items are.
 */
@interface GLLItemOptionalPartMarker : NSObject

- (id)initWithItem:(GLLItem *)item;
@property (nonatomic, readonly) GLLItem *item;

@end
