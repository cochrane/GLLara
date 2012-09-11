//
//  GLLItemViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 11.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemViewController.h"

#import "GLLItem.h"

@interface GLLItemViewController ()

@end

@implementation GLLItemViewController

- (id)init
{
    self = [super initWithNibName:@"GLLItemView" bundle:nil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)loadPose:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.pose" ];
	[panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		NSError *error = nil;
		NSString *file = [NSString stringWithContentsOfURL:panel.URL usedEncoding:NULL error:&error];

		if (!file)
		{
			[self.view.window presentError:error];
			return;
		}
		
		if (![(GLLItem *) self.representedObject loadPose:file error:&error])
		{
			[self.view.window presentError:error];
			return;
		}
	}];

}

- (void)savePose:(id)sender
{
	NSBeep();
}

@end
