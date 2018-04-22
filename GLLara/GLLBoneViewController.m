//
//  GLLBoneViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLBoneViewController.h"

#import "GLLItemBone.h"

@interface GLLBoneViewController ()

@end

@implementation GLLBoneViewController

- (id)init
{
    if (!(self = [super initWithNibName:@"GLLBoneView" bundle:[NSBundle mainBundle]]))
        return nil;
    
    return self;
}

- (IBAction)resetAllValues:(id)sender;
{
    [(GLLItemBone *) [self.representedObject valueForKey:@"self"] resetAllValues];
}

- (IBAction)resetAllValuesAndChildren:(id)sender;
{
    [(GLLItemBone *) [self.representedObject valueForKey:@"self"] resetAllValuesRecursively];
}

- (IBAction)help:(id)sender;
{
    NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    [[NSHelpManager sharedHelpManager] openHelpAnchor:@"bones" inBook:locBookName];
}

@end
