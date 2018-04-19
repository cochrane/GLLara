//
//  GLLOptionalPart.h
//  GLLara
//
//  Created by Torsten Kammer on 19.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItem;

// Representation of an optional part. Optional parts are a view-only concept
// that does not appear in the model layer; it's just a name, an item, and a
// bit of logic to determine whether the part is selected and change that state
// by looking at the state of all the relevant items.
//
// This class is only used by the view layer to allow simple bindings.
@interface GLLOptionalPart : NSObject

- (id)initWithItem:(GLLItem *)item name:(NSString *)name;

@property (nonatomic, readonly) GLLItem *item;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic) id visible;

@end
