//
//  GLLDocument.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocument.h"

#import "GLLAmbientLight.h"
#import "GLLAngleRangeValueTransformer.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLDocumentWindowController.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLItemController.h"
#import "GLLItemExportViewController.h"
#import "GLLItemMesh.h"
#import "GLLItem+OBJExport.h"
#import "GLLLogarithmicValueTransformer.h"
#import "GLLModel.h"
#import "GLLRenderWindowController.h"
#import "TR1Level.h"
#import "TRItemSelectWindowController.h"
#import "GLLSceneDrawer.h"
#import "GLLSourceListController.h"

@interface GLLDocument () <NSOpenSavePanelDelegate>
{
	GLLDocumentWindowController *documentWindowController;
	TRItemSelectWindowController *itemController;
	GLLSceneDrawer *sceneDrawer;
	GLLSourceListController *sourceListController;
}

@end

@implementation GLLDocument

+ (void)initialize
{
	[NSValueTransformer setValueTransformer:[[GLLAngleRangeValueTransformer alloc] init] forName:@"GLLAngleRangeValueTransformer"];
	[NSValueTransformer setValueTransformer:[[GLLLogarithmicValueTransformer alloc] init] forName:@"GLLLogarithmicValueTransformer"];
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	if (!(self = [super initWithType:typeName error:outError]))
		return nil;
	
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager disableUndoRegistration];
	// Prepare the default lights
	
	// One ambient light
	GLLAmbientLight *ambientLight = [NSEntityDescription insertNewObjectForEntityForName:@"GLLAmbientLight" inManagedObjectContext:self.managedObjectContext];
	ambientLight.color = [NSColor darkGrayColor];
	ambientLight.index = 0;
	
	// Three directional lights.
	for (int i = 0; i < 3; i++)
	{
		GLLDirectionalLight *directionalLight = [NSEntityDescription insertNewObjectForEntityForName:@"GLLDirectionalLight" inManagedObjectContext:self.managedObjectContext];
		directionalLight.isEnabled = (i == 0);
		directionalLight.diffuseColor = [NSColor whiteColor];
		directionalLight.specularColor = [NSColor whiteColor];
		directionalLight.index = i + 1;
	}
	
	// Prepare standard camera
	[NSEntityDescription insertNewObjectForEntityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager enableUndoRegistration];
	
	return self;
}

- (void)makeWindowControllers
{
	sceneDrawer = [[GLLSceneDrawer alloc] initWithManagedObjectContext:self.managedObjectContext];
	
	documentWindowController = [[GLLDocumentWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:documentWindowController];

	NSFetchRequest *camerasFetchRequest = [[NSFetchRequest alloc] init];
	camerasFetchRequest.entity = [NSEntityDescription entityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	camerasFetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	NSArray *cameras = [self.managedObjectContext executeFetchRequest:camerasFetchRequest error:NULL];
	
	for (GLLCamera *camera in cameras)
	{
		GLLRenderWindowController *controller = [[GLLRenderWindowController alloc] initWithCamera:camera sceneDrawer:sceneDrawer];
		[self addWindowController:controller];
	}
}

#pragma mark - Actions

- (IBAction)openNewRenderView:(id)sender
{
	// 1st: Find an index for the new render view.
	NSFetchRequest *highestIndexRequest = [[NSFetchRequest alloc] init];
	highestIndexRequest.entity = [NSEntityDescription entityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	highestIndexRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO] ];
	highestIndexRequest.fetchLimit = 1;
	NSArray *highestCameras = [self.managedObjectContext executeFetchRequest:highestIndexRequest error:NULL];
	NSUInteger index;
	if (highestCameras.count > 0)
		index = [[highestCameras objectAtIndex:0] index] + 1;
	else
		index = 0;
	
	// 2nd: Create that camera object
	GLLCamera *camera = [NSEntityDescription insertNewObjectForEntityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	camera.index = index;
	
	// 3rd: Create its window controller
	GLLRenderWindowController *controller = [[GLLRenderWindowController alloc] initWithCamera:camera sceneDrawer:sceneDrawer];
	[self addWindowController:controller];
	[controller showWindow:sender];
}
- (IBAction)loadMesh:(id)sender;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.mesh", @"obj", @"com.square-enix.tombraider1234" ];
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		NSString *type = (__bridge_transfer NSString *) UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)panel.URL.pathExtension, kUTTypeData);
		if ([type isEqual:@"com.square-enix.tombraider1234"])
		{
			dispatch_after(1, dispatch_get_current_queue(), ^{
				NSError *error = nil;
				NSData *data = [NSData dataWithContentsOfURL:panel.URL options:0 error:&error];
				if (!data)
				{
					[self.windowForSheet presentError:error];
					return;
				}
				TR1Level *level = [[TR1Level alloc] initWithData:data];
				if (!itemController)
					itemController = [[TRItemSelectWindowController alloc] init];
				itemController.level = level;
				
				[NSApp beginSheet:itemController.window modalForWindow:self.windowForSheet modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			});
		}
		else
		{
			NSError *error = nil;
			GLLModel *model = [GLLModel cachedModelFromFile:panel.URL error:&error];
			
			if (!model)
			{
				[self.windowForSheet presentError:error];
				return;
			}
			
			GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
			newItem.model = model;
		}
	}];
}

- (IBAction)delete:(id)sender;
{	
	for (id selectedObject in self.selectedObjects)
	{
		if ([selectedObject isKindOfClass:[GLLItemController class]])
			[self.managedObjectContext deleteObject:[selectedObject item]];
		else if ([selectedObject isKindOfClass:[GLLItemBone class]])
			[self.managedObjectContext deleteObject:[selectedObject item]];
		else if ([selectedObject isKindOfClass:[GLLItemMesh class]])
			[self.managedObjectContext deleteObject:[selectedObject item]];
		else
			NSBeep();
	}
}

- (IBAction)exportSelectedModel:(id)sender
{
	if (self.selectedObjects.count != 1)
	{
		NSBeep();
		return;
	}
	
	id selectedObject = [self.selectedObjects objectAtIndex:0];
	GLLItem *item = nil;
	if ([selectedObject isKindOfClass:[GLLItemController class]])
		item = [selectedObject item];
	else if ([selectedObject isKindOfClass:[GLLItemBone class]])
		item = [selectedObject item];
	else if ([selectedObject isKindOfClass:[GLLItemMesh class]])
		item = [selectedObject item];
	if (!item) return;
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.allowedFileTypes = @[ @"obj" ];
	panel.delegate = self;
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"objExportIncludeTransformations" : @YES, @"objExportIncludeVertexColors" : @NO }];
	
	GLLItemExportViewController *controller = [[GLLItemExportViewController alloc] init];
	controller.includeTransformations = [[NSUserDefaults standardUserDefaults] boolForKey:@"objExportIncludeTransformations"];
	controller.includeVertexColors = [[NSUserDefaults standardUserDefaults] boolForKey:@"objExportIncludeVertexColors"];
	controller.canExportAllData = ![item willLoseDataWhenConvertedToOBJ];
	
	panel.accessoryView = controller.view;
	
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		NSURL *objURL = panel.URL;
		NSString *materialLibraryName = [[objURL.lastPathComponent stringByDeletingPathExtension] stringByAppendingString:@".mtl"];
		NSURL *mtlURL = [NSURL URLWithString:materialLibraryName relativeToURL:objURL];
		
		NSError *error = nil;
		if (![item writeOBJToLocation:objURL withTransform:controller.includeTransformations withColor:controller.includeVertexColors error:&error])
		{
			[self.windowForSheet presentError:error];
			return;
		}
		if (![item writeMTLToLocation:mtlURL error:&error])
		{
			[self.windowForSheet presentError:error];
			return;
		}
	}];
	
}

#pragma mark - Accessors

- (GLLSourceListController *)sourceListController
{
	if (!sourceListController)
	{
		sourceListController = [[GLLSourceListController alloc] initWithManagedObjectContext:self.managedObjectContext];
		[self bind:@"selectedObjects" toObject:sourceListController withKeyPath:@"treeController.selectedObjects" options:nil];
	}
	return sourceListController;
}

- (void)setSelectedObjects:(NSArray *)selectedObjects
{
	NSAssert(sceneDrawer, @"Need to have scene drawer now.");
	
	_selectedObjects = selectedObjects;
	
	if (!selectedObjects || selectedObjects.count == 0)
	{
		[sceneDrawer setSelectedBones:@[]];
	}
	else if ([selectedObjects.lastObject isKindOfClass:[GLLItemBone class]])
	{
		[sceneDrawer setSelectedBones:selectedObjects];
	}
	else if ([selectedObjects.lastObject isKindOfClass:[GLLItemController class]])
	{
		NSMutableArray *allBones = [NSMutableArray array];
		for (GLLItemController *controller in selectedObjects)
		{
			[allBones addObjectsFromArray:[[controller valueForKeyPath:@"item.bones"] array]];
		}
		[sceneDrawer setSelectedBones:allBones];
	}
	else
	{
		[sceneDrawer setSelectedBones:@[]];
	}
}

#pragma mark - Save panel delegate

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
	if ([url.pathExtension isEqual:@"mtl"])
	{
		if (outError)
			*outError = [NSError errorWithDomain:self.className code:65 userInfo:@{
			   NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"OBJ files cannot use .mtl as extension", @"export: suffix = mtl"),
		  NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"As part of the export, an .mtl file will be generated automatically. To avoid clashes, do not use .mtl as an extension.", @"export: suffix = mtl")
						 }];
		return NO;
	}
	
	NSString *materialLibraryName = [[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingString:@".mtl"];
	NSURL *mtlURL = [NSURL URLWithString:materialLibraryName relativeToURL:url];
	
	if ([mtlURL checkResourceIsReachableAndReturnError:NULL])
	{
		NSAlert *mtlExistsAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"An MTL file with this name already exists", @"export: has such mtl already") defaultButton:nil alternateButton:NSLocalizedString(@"Cancel", @"export: cancel") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"As part of the export, an .mtl file will be generated automatically. This will overwrite an existing file of the same name.", @"export: suffix = mtl")];
		NSInteger result = [mtlExistsAlert runModal];
		return result == NSOKButton;
	}
	
	return YES;
}

@end
