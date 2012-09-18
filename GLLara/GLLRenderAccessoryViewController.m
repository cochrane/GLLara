//
//  GLLRenderAccessoryViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderAccessoryViewController.h"

#import "LionSubscripting.h"

@interface GLLRenderAccessoryViewController ()

@end

@implementation GLLRenderAccessoryViewController

- (id)init
{
    self = [super initWithNibName:@"GLLRenderAccessoryView" bundle:nil];
	
	NSArray *typeNames = (__bridge_transfer NSArray *) CGImageDestinationCopyTypeIdentifiers();
	
	NSMutableArray *types = [[NSMutableArray alloc] initWithCapacity:typeNames.count];
	
	for (NSString *type in typeNames)
	{
		[types addObject:@{ @"type" : type,
		 @"typeDescription" : (__bridge_transfer NSString *) UTTypeCopyDescription((__bridge CFStringRef) type) }];
	}
	
    self.fileTypes = [types copy];
	self.selectedFileType = self.fileTypes[0];
	
    return self;
}

- (void)setSelectedFileType:(NSDictionary *)selectedFileType
{
	_selectedFileType = selectedFileType;
	self.savePanel.allowedFileTypes = @[ selectedFileType[@"type"] ];
}

- (NSString *)selectedTypeIdentifier
{
	return self.selectedFileType[@"type"];
}

@end
