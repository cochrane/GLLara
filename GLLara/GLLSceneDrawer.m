//
//  GLLSceneDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSceneDrawer.h"

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "NSColor+Color32Bit.h"
#import "GLLAmbientLight.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLDocument.h"
#import "GLLDrawState.h"
#import "GLLItem.h"
#import "GLLNotifications.h"
#import "GLLRenderParameter.h"
#import "GLLResourceManager.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"
#import "GLLTiming.h"

#import "GLLara-Swift.h"

@interface GLLSceneDrawer ()
{
	NSMutableArray *itemDrawers;
	id managedObjectContextObserver;
    id drawStateNotificationObserver;
	GLLSkeletonDrawer *skeletonDrawer;
}

- (void)_addDrawerForItem:(GLLItem *)item;

@end

@implementation GLLSceneDrawer

- (id)initWithDocument:(GLLDocument *)document;
{
	if (!(self = [super init])) return nil;

	_document = document;
	_resourceManager = [GLLResourceManager sharedResourceManager];
	
	itemDrawers = [[NSMutableArray alloc] init];
	
	NSEntityDescription *itemEntity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	
	// Set up loading of future items and destroying items. Also update view.
	// Store self as weak in the block, so it does not retain this.
	__block __weak id weakSelf = self;
	managedObjectContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		GLLSceneDrawer *self = weakSelf;
				
		NSMutableArray *toRemove = [[NSMutableArray alloc] init];
		for (GLLItemDrawer *drawer in self->itemDrawers)
		{
			if (![notification.userInfo[NSDeletedObjectsKey] containsObject:drawer.item])
				continue;
			
			[toRemove addObject:drawer];
		}
		[self->itemDrawers removeObjectsInArray:toRemove];
				
		// New objects includes absolutely anything. Restrict this to items.
		for (NSManagedObject *newItem in notification.userInfo[NSInsertedObjectsKey])
		{
			if ([notification.userInfo[NSDeletedObjectsKey] containsObject:newItem])
				continue; // Objects that were deleted again before this was called.
			if ([newItem.entity isKindOfEntity:itemEntity])
				[self _addDrawerForItem:(GLLItem *) newItem];
		}
		
		[self notifyRedraw];
	}];
    
    drawStateNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GLLDrawStateChangedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        [self notifyRedraw];
    }];
	
	// Load existing items
	NSFetchRequest *allItemsRequest = [[NSFetchRequest alloc] init];
	allItemsRequest.entity = itemEntity;
	
	NSArray *allItems = [self.managedObjectContext executeFetchRequest:allItemsRequest error:NULL];
	for (GLLItem *item in allItems)
		[self _addDrawerForItem:item];
	
	skeletonDrawer = [[GLLSkeletonDrawer alloc] initWithResourceManager:self.resourceManager];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:managedObjectContextObserver];
}

- (void)drawShowingSelection:(BOOL)showSelection into:(id<MTLRenderCommandEncoder>)commandEncoder  lightsBuffer:(id<MTLBuffer>)lights transformBuffer:(id<MTLBuffer>)transform
{
    GLLBeginTiming("Draw/Solid");
	// 1st pass: Draw items that do not need blending. They use shaders without alpha test
	for (GLLItemDrawer *drawer in itemDrawers)
        [drawer drawSolidInto:commandEncoder];
    GLLEndTiming("Draw/Solid");
    GLLBeginTiming("Draw/AlphaOp");
	
	/*// 2nd pass: Draw blended items, but only those pixels that are "almost opaque"
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, self.resourceManager.alphaTestPassGreaterBuffer);
	
	glEnable(GL_BLEND);
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawAlphaInto:commandEncoder];
    
    GLLEndTiming("Draw/AlphaOp");
    GLLBeginTiming("Draw/AlphaTrans");
	// 3rd pass: Draw blended items, now only those things that are "mostly transparent".
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, self.resourceManager.alphaTestPassLessBuffer);
	
	glDepthMask(GL_FALSE);
	for (GLLItemDrawer *drawer in itemDrawers)
        [drawer drawAlphaInto:commandEncoder];
    GLLEndTiming("Draw/AlphaTrans");*/
	
	if (showSelection)
    {
        GLLBeginTiming("Draw/Skel");
        
        [skeletonDrawer drawInto:commandEncoder];
        
        GLLEndTiming("Draw/Skel");
	}
}

- (NSManagedObjectContext *)managedObjectContext {
    return self.document.managedObjectContext;
}

#pragma mark - Selection

- (void)setSelectedBones:(NSArray<GLLItemBone *> *)selectedBones;
{
	skeletonDrawer.selectedBones = selectedBones;
	[self notifyRedraw];
}
- (NSArray<GLLItemBone *> *)selectedBones
{
	return skeletonDrawer.selectedBones;
}

#pragma mark - Private methods

- (void)_addDrawerForItem:(GLLItem *)item;
{
	NSError *error = nil;
    GLLItemDrawer *drawer = [[GLLItemDrawer alloc] initWithItem:item sceneDrawer:self error:&error];
	
	if (!drawer)
	{
		[NSApp presentError:error];
		if (item.objectID.isTemporaryID)
		{
			// Temporary ID means this was not loaded from a file. Get rid of it.
			[item.managedObjectContext deleteObject:item];
		}
		
		return;
    }
    
    if (drawer.replacedTextures.count > 0) {
        [self.document notifyTexturesNotLoaded:drawer.replacedTextures];
    }
	
	[itemDrawers addObject:drawer];
}

- (void)notifyRedraw;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLLSceneDrawerNeedsUpdateNotification object:self];
}

@end
