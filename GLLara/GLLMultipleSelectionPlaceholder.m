//
//  GLLMultipleSelectionPlaceholder.m
//  GLLara
//
//  Created by Torsten Kammer on 23.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLMultipleSelectionPlaceholder.h"

@interface GLLMultipleSelectionPlaceholder()

@end

@implementation GLLMultipleSelectionPlaceholder

@synthesize multipleSelectionMarker;
@synthesize emptySelectionMarker;
@synthesize value;

- (id)valueFrom:(id)sourceObject
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)setValue:(id)value onSourceObject:(id)object
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)update
{
    [self willChangeValueForKey:@"value"];
    
    value = nil;
    for (id object in self.selection) {
        id newValue = [self valueFrom:object];
        if (!value) {
            value = newValue;
        } else if (![newValue isEqual:value]) {
            value = self.multipleSelectionMarker;
            break;
        }
    }
    
    [self didChangeValueForKey:@"value"];
}

- (void)setValue:(id)aValue
{
    [self willChangeValueForKey:@"value"];
    
    value = aValue;
    for (id object in self.selection) {
        [self setValue:value onSourceObject:object];
    }
    
    [self didChangeValueForKey:@"value"];
}

@end
