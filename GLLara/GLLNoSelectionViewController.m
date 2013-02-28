//
//  GLLNoSelectionViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 28.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLNoSelectionViewController.h"

@interface GLLNoSelectionViewController ()

@end

@implementation GLLNoSelectionViewController

- (id)init
{
    self = [super initWithNibName:@"GLLNoSelectionView" bundle:nil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)help:(id)sender;
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"models" inBook:locBookName];
}

@end
