//
//  GLLItemViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 11.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemViewController.h"

#import "GLLItem.h"
#import "GLLItemMesh.h"
#import "GLLItemMeshTexture.h"
#import "GLLModel.h"

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

- (IBAction)help:(id)sender;
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"models" inBook:locBookName];
}

- (void)loadPose:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.pose" ];
	[panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
		NSError *error = nil;
		NSString *file = [NSString stringWithContentsOfURL:panel.URL usedEncoding:NULL error:&error];

		if (!file)
		{
			[self.view.window presentError:error];
			return;
		}
		
		self.undoManager.actionName = NSLocalizedString(@"Load pose", @"load pose undo action name");
		for (GLLItem *item in self.selectedItems)
		{
			if (![item loadPose:file error:&error])
			{
				[self.view.window presentError:error];
				return;
			}
		}
	}];
}
- (IBAction)loadChildModel:(id)sender;
{
	if (self.selectedItems.count != 1)
	{
		NSBeep();
		return;
	}
	GLLItem *item = self.selectedItems[0];
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.mesh", @"obj" ];
	[panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
		NSError *error = nil;
		GLLModel *model = [GLLModel cachedModelFromFile:panel.URL parent:item.model error:&error];
		
		if (!model)
		{
			[self.view.window presentError:error];
			return;
		}
		
		self.undoManager.actionName = NSLocalizedString(@"Load outift", @"load child model undo action name");
		
		GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:item.managedObjectContext];
		newItem.parent = item;
		newItem.model = model;
	}];
}
- (IBAction)loadTexturePack:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.canChooseDirectories = YES;
	panel.canChooseFiles = NO;
	[panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
		NSURL *directoryURL = panel.URL;
		
		self.undoManager.actionName = NSLocalizedString(@"Load texture pack", @"load texture pack undo action name");
		
		for (GLLItem *item in self.selectedItems)
		{
			for (GLLItemMesh *mesh in [item valueForKeyPath:@"meshes"])
			{
				for (GLLItemMeshTexture *texture in [mesh valueForKeyPath:@"textures"])
				{
					NSString *name = texture.textureURL.lastPathComponent;
					NSURL *newURL = [directoryURL URLByAppendingPathComponent:name isDirectory:NO];
					if ([newURL checkResourceIsReachableAndReturnError:NULL])
						texture.textureURL = newURL;
				}
			}
		}
	}];
}

@end
