//
//  GLLLightViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLLightViewController.h"

@interface GLLLightViewController ()

@end

@implementation GLLLightViewController

- (id)init
{
    self = [super initWithNibName:@"GLLLightView" bundle:nil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)loadView
{
	// Load explicitly with this method, to make sure it goes through DMLocalizedNibBundle.
	[NSBundle loadNibNamed:self.nibName owner:self];
}

- (IBAction)help:(id)sender;
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"diffuselight" inBook:locBookName];
}

@end
