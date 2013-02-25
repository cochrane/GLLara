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

- (void)loadView
{
	// Load explicitly with this method, to make sure it goes through DMLocalizedNibBundle.
	[NSBundle loadNibNamed:self.nibName owner:self];
}

@end
