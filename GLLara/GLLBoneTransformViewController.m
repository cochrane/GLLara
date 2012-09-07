//
//  GLLBoneTransformViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLBoneTransformViewController.h"

@interface GLLBoneTransformViewController ()

@end

@implementation GLLBoneTransformViewController

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLBoneTransformView" bundle:[NSBundle mainBundle]]))
		return nil;
	
	return self;
}

- (IBAction)resetAllValues:(id)sender;
{
	[self.representedObject setValue:@0 forKey:@"rotationX"];
	[self.representedObject setValue:@0 forKey:@"rotationY"];
	[self.representedObject setValue:@0 forKey:@"rotationZ"];
	[self.representedObject setValue:@0 forKey:@"positionX"];
	[self.representedObject setValue:@0 forKey:@"positionY"];
	[self.representedObject setValue:@0 forKey:@"positionZ"];
}

@end
