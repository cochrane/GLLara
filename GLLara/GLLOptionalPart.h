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

- (instancetype _Nonnull)initWithItem:(GLLItem * _Nonnull)item name:(NSString * _Nonnull)name parent:(GLLOptionalPart * _Nullable)parent;

@property (nonatomic, readonly) GLLItem * _Nonnull item;
@property (nonatomic, readonly) NSString * _Nonnull name;
@property (nonatomic) id _Nonnull visible;

@property (nonatomic, weak) GLLOptionalPart * _Nullable parent;

@property (nonatomic, copy, readonly) NSArray<GLLOptionalPart *> * _Nonnull children;
- (GLLOptionalPart *_Nullable)childWithName:(NSString * _Nonnull)name;
@property (nonatomic, readonly) BOOL hasNoChildren;
@property (nonatomic, readonly) NSUInteger numberOfChildren;

@end
