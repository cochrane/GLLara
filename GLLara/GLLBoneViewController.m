//
//  GLLBoneViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLBoneViewController.h"

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
    [self.representedObject setValue:@0 forKey:@"rotationX"];
    [self.representedObject setValue:@0 forKey:@"rotationY"];
    [self.representedObject setValue:@0 forKey:@"rotationZ"];
    [self.representedObject setValue:@0 forKey:@"positionX"];
    [self.representedObject setValue:@0 forKey:@"positionY"];
    [self.representedObject setValue:@0 forKey:@"positionZ"];
}

- (IBAction)help:(id)sender;
{
    NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    [[NSHelpManager sharedHelpManager] openHelpAnchor:@"bones" inBook:locBookName];
}

@end
