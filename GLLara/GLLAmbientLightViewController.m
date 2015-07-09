//
//  GLLAmbientLightViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLAmbientLightViewController.h"

@interface GLLAmbientLightViewController ()

@end

@implementation GLLAmbientLightViewController

- (id)init
{
    self = [super initWithNibName:@"GLLAmbientLightView" bundle:nil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)help:(id)sender;
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"ambientlight" inBook:locBookName];
}

@end
