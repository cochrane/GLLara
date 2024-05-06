//
//  GLLOptionalPartController.m
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "GLLOptionalPartController.h"

#import "GLLara-Swift.h"

@implementation GLLOptionalPartController

- (id)initWithItem:(GLLItem *)item parent:(id)parentController;
{
    if (!(self = [super init])) return nil;
    
    _representedObject = [[GLLItemOptionalPartMarker alloc] initWithItem:item];
    _parentController = parentController;
    
    return self;
}

- (GLLItem *)item {
    return _representedObject.item;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return NSLocalizedString(@"Optional parts", @"source view optional parts");
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return 0;
}

@end
