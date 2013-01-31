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

- (BOOL)exportOnlySelectedBones
{
	return self.selectionMode == 0;
}

@end
