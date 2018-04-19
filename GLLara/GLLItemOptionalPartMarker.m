//
//  GLLItemOptionalPartMarker.m
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "GLLItemOptionalPartMarker.h"

#import "GLLItem.h"

@implementation GLLItemOptionalPartMarker

- (id)initWithItem:(GLLItem *)item {
    if (!(self = [super init]))
        return nil;
    
    _item = item;
    
    return self;
}

- (NSUInteger)hash {
    return [self.item hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[self class]])
        return NO;
    
    return [self.item isEqual:[(GLLItemOptionalPartMarker *) object item]];
}

@end
