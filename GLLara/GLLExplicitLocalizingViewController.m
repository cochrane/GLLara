//
//  GLLExplicitLocalizingViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLExplicitLocalizingViewController.h"

@interface GLLExplicitLocalizingViewController ()

@end

@implementation GLLExplicitLocalizingViewController

- (void)loadView
{
	// Load explicitly with this method, to make sure it goes through DMLocalizedNibBundle.
	[NSBundle loadNibNamed:self.nibName owner:self];
}

@end
