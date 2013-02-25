//
//  GLLPoseExportViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 31.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLPoseExportViewController.h"

@interface GLLPoseExportViewController ()

@end

@implementation GLLPoseExportViewController

- (id)init
{
	return [self initWithNibName:@"GLLPoseExportViewController" bundle:nil];
}

- (void)loadView
{
	// Load explicitly with this method, to make sure it goes through DMLocalizedNibBundle.
	[NSBundle loadNibNamed:self.nibName owner:self];
}

- (void)setExportOnlySelectedBones:(BOOL)exportOnlySelectedBones
{
	if (exportOnlySelectedBones)
		self.selectionMode = 0;
	else
		self.selectionMode = 1;
}

- (BOOL)exportOnlySelectedBones
{
	return self.selectionMode == 0;
}

@end
