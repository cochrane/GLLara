//
//  GLLRenderAccessoryViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderAccessoryViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "NSArray+Map.h"

@implementation GLLRenderAccessoryViewController

- (id)init
{
    self = [super initWithNibName:@"GLLRenderAccessoryView" bundle:nil];
    
    NSArray<NSString *> *typeNames = (__bridge_transfer NSArray *) CGImageDestinationCopyTypeIdentifiers();
    NSMutableArray<UTType*>* fileTypes = [[NSMutableArray alloc] initWithCapacity:typeNames.count];
    
    for (NSString *typeName in typeNames) {
        UTType* type = [UTType typeWithIdentifier:typeName];
        if (type) {
            [fileTypes addObject:type];
        }
    }
    
    self.fileTypes = [fileTypes copy];
    self.selectedFileType = self.fileTypes[0];
    
    return self;
}

- (void)setSelectedFileType:(UTType *)selectedFileType
{
    _selectedFileType = selectedFileType;
    self.savePanel.allowedContentTypes = @[ selectedFileType ];
}

- (NSUInteger)minSize {
    return 128;
}

- (NSUInteger)maxSize {
    return 16384;
}

@end
