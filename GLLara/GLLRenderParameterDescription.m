//
//  GLLRenderParameterDescription.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderParameterDescription.h"

NSString *GLLRenderParameterTypeFloat = @"float";
NSString *GLLRenderParameterTypeColor = @"color";

@implementation GLLRenderParameterDescription

- (id)initWithPlist:(NSDictionary *)plist;
{
    if (!(self = [super init])) return nil;
    
    _min = [plist[@"min"] floatValue];
    _max = [plist[@"max"] floatValue];
    _localizedTitle = [[NSBundle mainBundle] localizedStringForKey:plist[@"title"] value:nil table:@"RenderParameters"];
    _localizedDescription = [[NSBundle mainBundle] localizedStringForKey:plist[@"description"] value:nil table:@"RenderParameters"];
    
    _type = plist[@"type"];
    if (!_type) _type = GLLRenderParameterTypeFloat;
    
    return self;
}

- (NSUInteger)hash
{
    NSUInteger hash = (NSUInteger) _min;
    hash = 31 * hash + (NSUInteger) _max;
    hash = 31 * hash + _localizedDescription.hash;
    hash = 31 * hash + _localizedTitle.hash;
    hash = 31 * hash + _type.hash;
    return hash;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isMemberOfClass:self.class]) {
        return NO;
    } else {
        GLLRenderParameterDescription *otherDescription = other;
        return otherDescription.min == self.min
        && otherDescription.min == self.max
        && [otherDescription.localizedTitle isEqual:self.localizedTitle]
        && [otherDescription.localizedDescription isEqual:self.localizedDescription]
        && [otherDescription.type isEqual:self.type];
    }
}

@end
