//
//  GLLMeshSettingsViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLMeshSettingsViewController : NSViewController

// There is no need for a status display, but without, the view looks too damn empty.
@property (nonatomic, readonly) NSString *statusDisplay;

@end
