//
//  GLLRenderAccessoryViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderAccessoryViewController.h"

#import "NSArray+Map.h"

@interface GLLRenderViewAccessoryControllerFileType : NSObject

- (instancetype)initWithType:(NSString *)type;

@property (nonatomic, readonly) NSString *type; // UTI
@property (nonatomic, readonly) NSString *typeDescription; // User-readable

@end

@implementation GLLRenderViewAccessoryControllerFileType

- (instancetype)initWithType:(NSString *)type;
{
    self = [super init];
    
    _type = type;
    
    return self;
}

- (NSString *)typeDescription {
    NSString *description = (__bridge_transfer NSString *) UTTypeCopyDescription((__bridge CFStringRef) self.type);
    return description ? description : self.type;
}

@end

@implementation GLLRenderAccessoryViewController

- (id)init
{
    self = [super initWithNibName:@"GLLRenderAccessoryView" bundle:nil];
    
    NSArray<NSString *> *typeNames = (__bridge_transfer NSArray *) CGImageDestinationCopyTypeIdentifiers();
    
    self.fileTypes = [typeNames map:^(NSString *type){
        return [[GLLRenderViewAccessoryControllerFileType alloc] initWithType:type];
    }];
    self.selectedFileType = self.fileTypes[0];
    
    return self;
}

- (void)setSelectedFileType:(GLLRenderViewAccessoryControllerFileType *)selectedFileType
{
    _selectedFileType = selectedFileType;
    self.savePanel.allowedFileTypes = @[ selectedFileType.type ];
}

- (NSString *)selectedTypeIdentifier
{
    return self.selectedFileType.type;
}

@end
