//
//  GLLRenderAccessoryViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderAccessoryViewController.h"

#import "LionSubscripting.h"
#import "NSArray+Map.h"

@interface GLLRenderAccessoryViewController ()

@end

@implementation GLLRenderAccessoryViewController

- (id)init
{
    self = [super initWithNibName:@"GLLRenderAccessoryView" bundle:nil];
	
	NSArray *typeNames = (__bridge_transfer NSArray *) CGImageDestinationCopyTypeIdentifiers();
	
	self.fileTypes = [typeNames map:^(NSString *type){
		NSString *description = (__bridge_transfer NSString *) UTTypeCopyDescription((__bridge CFStringRef) type);
		if (!description) description = type;
		return @{ @"type" : type,
		@"typeDescription" : description };
	}];
	self.selectedFileType = self.fileTypes[0];
	
    return self;
}

- (void)loadView
{
	// Load explicitly with this method, to make sure it goes through DMLocalizedNibBundle.
	[NSBundle loadNibNamed:self.nibName owner:self];
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
