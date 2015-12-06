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
#import "GLLItem+MeshExport.h"
#import "GLLItemBone.h"
#import "GLLItemExportViewController.h"
#import "GLLItemMesh.h"
#import "GLLItem+OBJExport.h"
#import "GLLLogarithmicValueTransformer.h"
#import "GLLModel.h"
#import "GLLPreferenceKeys.h"
#import "GLLPoseExporter.h"
#import "GLLPoseExportViewController.h"
#import "GLLRenderWindowController.h"
#import "GLLSceneDrawer.h"
#import "GLLSelection.h"

@interface GLLDocument () <NSOpenSavePanelDelegate>
{
	GLLDocumentWindowController *documentWindowController;
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
	_selection = [[GLLSelection alloc] initWithManagedObjectContext:self.managedObjectContext];
	
	sceneDrawer = [[GLLSceneDrawer alloc] initWithManagedObjectContext:self.managedObjectContext];
	[sceneDrawer bind:@"selectedBones" toObject:self.selection withKeyPath:@"selectedBones" options:nil];
	
    documentWindowController = [[GLLDocumentWindowController alloc] initWithManagedObjectContext:self.managedObjectContext selection:self.selection];
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

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError *__autoreleasing *)error
{
	NSMutableDictionary *allOptions = [@{ NSMigratePersistentStoresAutomaticallyOption : @(YES), NSInferMappingModelAutomaticallyOption : @(YES) } mutableCopy];
	if (storeOptions)
		[allOptions addEntriesFromDictionary:storeOptions];
	return [super configurePersistentStoreCoordinatorForURL:url ofType:fileType modelConfiguration:configuration storeOptions:allOptions error:error];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error
{
	BOOL result = [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:error];
	if (!result)
		NSLog(@"couldn't save. Error: %@", error ? *error : nil);
	return result;
}

#pragma mark - Adding models

- (GLLItem *)addModelAtURL:(NSURL *)url error:(NSError *__autoreleasing*)error;
{
	GLLModel *model = [GLLModel cachedModelFromFile:url parent:nil error:error];
	if (!model) return nil;
	
	return [self addModel:model];
}

- (GLLItem *)addModel:(GLLModel *)model;
{
	GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	newItem.model = model;
	
	self.undoManager.actionName = NSLocalizedString(@"Add item", @"load mesh undo action name");
	
	// Set selection next time the main loop comes around to ensure everything's set up properly by then.
	dispatch_async(dispatch_get_main_queue(), ^(){
		NSMutableArray *selectedItems = [self.selection mutableArrayValueForKeyPath:@"selectedItems"];
		[selectedItems replaceObjectsInRange:NSMakeRange(0, selectedItems.count) withObjectsFromArray:@[ newItem ]];
	});
	return newItem;
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
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.mesh", @"obj" ];
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
		NSError *error = nil;
        [self addModelAtURL:panel.URL error:&error];
        if (error)
			[self presentError:error modalForWindow:self.windowForSheet delegate:nil didPresentSelector:NULL contextInfo:NULL];
	}];
}

- (IBAction)delete:(id)sender;
{
	NSAssert([[self.selection valueForKeyPath:@"selectedItems"] count] >= 1, @"Can only delete if at least one item is selected.");
	
	for (GLLItem *item in [self.selection valueForKeyPath:@"selectedItems"])
		[self.managedObjectContext deleteObject:item];
	[self.managedObjectContext processPendingChanges];
	
	self.undoManager.actionName = NSLocalizedString(@"Delete item", @"delete item undo action name");
}

- (IBAction)exportSelectedModel:(id)sender
{
	NSAssert([[self.selection valueForKeyPath:@"selectedItems"] count] == 1, @"Can only export if exactly one item is selected");
	GLLItem *item = [[self.selection valueForKeyPath:@"selectedItems"] objectAtIndex:0];
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.allowedFileTypes = @[ @"obj" ];
	panel.delegate = self;
	
	GLLItemExportViewController *controller = [[GLLItemExportViewController alloc] init];
	controller.includeTransformations = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefObjExportIncludesTransforms];
	controller.includeVertexColors = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefObjExportIncludesVertexColors];
	controller.canExportAllData = ![item willLoseDataWhenConvertedToOBJ];
	
	panel.accessoryView = controller.view;
	
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
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

- (IBAction)exportSelectedPose:(id)sender;
{
	NSAssert([[self.selection valueForKeyPath:@"selectedItems"] count] == 1, @"Can only export if exactly one item is selected");
	NSAssert([[self.selection valueForKeyPath:@"selectedBones"] count] != 0, @"Can only export if some bones are selected");
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.pose" ];
	
	GLLPoseExportViewController *controller = [[GLLPoseExportViewController alloc] init];
	panel.accessoryView = controller.view;
	
	controller.exportUnusedBones = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefPoseExportIncludesUnused];
	controller.exportOnlySelectedBones = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefPoseExportOnlySelected];
	
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
		[[NSUserDefaults standardUserDefaults] setBool:controller.exportUnusedBones forKey:GLLPrefPoseExportIncludesUnused];
		[[NSUserDefaults standardUserDefaults] setBool:controller.exportOnlySelectedBones forKey:GLLPrefPoseExportOnlySelected];
		
		GLLPoseExporter *exporter = nil;
		if (controller.exportOnlySelectedBones)
			exporter = [[GLLPoseExporter alloc] initWithBones:[self.selection valueForKeyPath:@"selectedBones"]];
		else
		{
			GLLItem *selectedItem = ([[self.selection valueForKey:@"selectedItems"] count] > 0) ? [self.selection valueForKey:@"selectedItems"][0] : [[self.selection valueForKey:@"selectedBones"][0] item];
			exporter = [[GLLPoseExporter alloc] initWithItem:selectedItem];
		}
		
		exporter.skipUnused = !controller.exportUnusedBones;
		
		NSError *error = nil;
		if (![exporter.poseDescription writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error])
			[self.windowForSheet presentError:error];
	}];
}
- (IBAction)exportItem:(id)sender;
{
	NSAssert([[self.selection valueForKeyPath:@"selectedItems"] count] == 1, @"Can only export if exactly one item is selected");
	
	GLLItem *item = [[self.selection valueForKeyPath:@"selectedItems"] objectAtIndex:0];
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.canCreateDirectories = YES;
	panel.allowedFileTypes = @[ (__bridge NSString *) kUTTypeFolder ];
	
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSModalResponseOK) return;
		
		NSFileManager *manager = [NSFileManager defaultManager];
		NSError *error = nil;
		
		// Create new folder
		if (![manager createDirectoryAtURL:panel.URL withIntermediateDirectories:YES attributes:nil error:&error])
		{
			[self.windowForSheet presentError:error];
			return;
		}
		
		// Copy textures to folder
		NSMutableSet *copiedTextures = [NSMutableSet set];
		for (GLLItemMesh *mesh in [item valueForKeyPath:@"meshes"])
		{
			for (NSURL *textureURL in [mesh valueForKeyPath:@"textures.textureURL.absoluteURL"])
			{
				if ([copiedTextures containsObject:textureURL])
					continue;
				
				[copiedTextures addObject:textureURL];
				
				NSURL *targetURL = [panel.URL URLByAppendingPathComponent:textureURL.lastPathComponent];
				if ([targetURL checkResourceIsReachableAndReturnError:NULL])
					continue;
				if (![manager copyItemAtURL:textureURL toURL:targetURL error:&error])
				{
					[manager removeItemAtURL:panel.URL error:NULL];
					[self.windowForSheet presentError:error];
					return;
				}
			}
		}
		
		// Save mesh file there - both with and without ascii
		NSString *ascii = [item writeASCIIError:&error];
		if (!ascii)
		{
			[manager removeItemAtURL:panel.URL error:NULL];
			[self.windowForSheet presentError:error];
			return;
		}
		if (![ascii writeToURL:[panel.URL URLByAppendingPathComponent:@"generic_item.mesh.ascii"] atomically:YES encoding:NSUTF8StringEncoding error:&error])
		{
			[manager removeItemAtURL:panel.URL error:NULL];
			[self.windowForSheet presentError:error];
			return;
		}
		
		// Ignore if writing binary fails; the mesh.ascii version includes all data already.
		NSData *binary = [item writeBinaryError:NULL];
		if (!binary) return;
		if (![binary writeToURL:[panel.URL URLByAppendingPathComponent:@"generic_item.mesh"] options:NSDataWritingAtomic error:&error]) return;
	}];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)item
{
	// Always valid
	if (item.action == @selector(openNewRenderView:)) return YES;
	else if (item.action == @selector(loadMesh:)) return YES;
	// Conditional
	if (item.action == @selector(delete:))
		return [[self.selection valueForKeyPath:@"selectedItems"] count] >= 1;
	else if (item.action == @selector(exportSelectedModel:))
		return [[self.selection valueForKeyPath:@"selectedItems"] count] == 1;
	else if (item.action == @selector(exportSelectedPose:))
		return [[self.selection valueForKeyPath:@"selectedItems"] count] <= 1 && [[self.selection valueForKeyPath:@"selectedBones"] count] != 0;
	else if (item.action == @selector(exportItem:))
		return [[self.selection valueForKeyPath:@"selectedItems"] count] == 1;
	else
		return [super validateUserInterfaceItem:item];
}

#pragma mark - Accessors

- (GLLSourceListController *)sourceListController
{
//	if (!sourceListController)
//	{
//		sourceListController = [[GLLSourceListController alloc] initWithManagedObjectContext:self.managedObjectContext];
//		[self.selection bind:@"selectedObjects" toObject:sourceListController.treeController withKeyPath:@"selectedObjects" options:nil];
//	}
//	return sourceListController;
	return nil;
}

- (NSArray *)allBones
{
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"GLLItemBone"];
	return [self.managedObjectContext executeFetchRequest:request error:NULL];
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
        NSAlert *mtlExistsAlert = [[NSAlert alloc] init];
        mtlExistsAlert.messageText = NSLocalizedString(@"An MTL file with this name already exists", @"export: has such mtl already");
        mtlExistsAlert.informativeText = NSLocalizedString(@"As part of the export, an .mtl file will be generated automatically. This will overwrite an existing file of the same name.", @"export: suffix = mtl");
        [mtlExistsAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"export: cancel")];
        [mtlExistsAlert addButtonWithTitle:@"OK"];
        
		NSInteger result = [mtlExistsAlert runModal];
		return result == NSAlertSecondButtonReturn;
	}
	
	return YES;
}

@end
