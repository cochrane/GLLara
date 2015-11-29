//
//  GLLMultipleSelectionPlaceholder.m
//  GLLara
//
//  Created by Torsten Kammer on 23.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLMultipleSelectionPlaceholder.h"

#import <AppKit/AppKit.h>

#import "GLLSelection.h"

@interface GLLMultipleSelectionPlaceholder()

@property (nonatomic, retain) GLLSelection *selection;
@property (nonatomic, retain) NSString *selectionTypeKey;
@property (nonatomic, retain) id undoNotificationRegistration;
@property (nonatomic, retain) id redoNotificationRegistration;

@end

@implementation GLLMultipleSelectionPlaceholder

@synthesize multipleSelectionMarker;
@synthesize value;

- (instancetype)initWithSelection:(GLLSelection *)selection typeKey:(NSString *)selectionTypeKey;
{
    NSParameterAssert(selection);
    NSParameterAssert(selectionTypeKey);
    
    if (!(self = [super init]))
        return nil;
    
    _selection = selection;
    _selectionTypeKey = selectionTypeKey;
    [selection addObserver:self forKeyPath:selectionTypeKey options:NSKeyValueObservingOptionNew context:0];
    __weak GLLMultipleSelectionPlaceholder *weakSelf = self;
    
    _undoNotificationRegistration = [[NSNotificationCenter defaultCenter] addObserverForName:NSUndoManagerDidUndoChangeNotification object:nil queue:nil usingBlock:^(NSNotification *n) {
        [weakSelf update];
    }];
    _redoNotificationRegistration = [[NSNotificationCenter defaultCenter] addObserverForName:NSUndoManagerDidRedoChangeNotification object:nil queue:nil usingBlock:^(NSNotification *n) {
        [weakSelf update];
    }];
    
    multipleSelectionMarker = NSMultipleValuesMarker;
    emptySelectionMarker = NSNoSelectionMarker;

    return self;
}

- (void)dealloc
{
    [_selection removeObserver:self forKeyPath:_selectionTypeKey];
    [[NSNotificationCenter defaultCenter] removeObserver:_undoNotificationRegistration];
    [[NSNotificationCenter defaultCenter] removeObserver:_redoNotificationRegistration];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.selection]) {
        [self update];
    }
}

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
    for (id object in [self.selection valueForKeyPath:self.selectionTypeKey]) {
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
    for (id object in [self.selection valueForKeyPath:self.selectionTypeKey]) {
        [self setValue:value onSourceObject:object];
    }
    
    [self didChangeValueForKey:@"value"];
}

@end
