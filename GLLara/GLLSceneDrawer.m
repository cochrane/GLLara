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
#import "GLLItemDrawer.h"
#import "GLLModelProgram.h"
#import "GLLNotifications.h"
#import "GLLRenderParameter.h"
#import "GLLResourceManager.h"
#import "GLLUniformBlockBindings.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"
#import "GLLSkeletonDrawer.h"
#import "GLLTiming.h"

@interface GLLSceneDrawer ()
{
	NSMutableArray *itemDrawers;
	id managedObjectContextObserver;
    id drawStateNotificationObserver;
	GLLSkeletonDrawer *skeletonDrawer;
	GLLDrawState state;
}

- (void)_addDrawerForItem:(GLLItem *)item;
- (void)_unregisterDrawer:(GLLItemDrawer *)drawer;
- (void)_notifyRedraw;

@end

@implementation GLLSceneDrawer

- (id)initWithDocument:(GLLDocument *)document;
{
	if (!(self = [super init])) return nil;

	_document = document;
	_resourceManager = [GLLResourceManager sharedResourceManager];
	[_resourceManager.openGLContext makeCurrentContext];
	
	itemDrawers = [[NSMutableArray alloc] init];
	
	NSEntityDescription *itemEntity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	
	// Set up loading of future items and destroying items. Also update view.
	// Store self as weak in the block, so it does not retain this.
	__block __weak id weakSelf = self;
	managedObjectContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		GLLSceneDrawer *self = weakSelf;
		
		// Ensure proper OpenGL context
		[self->_resourceManager.openGLContext makeCurrentContext];
		
		NSMutableArray *toRemove = [[NSMutableArray alloc] init];
		for (GLLItemDrawer *drawer in self->itemDrawers)
		{
			if (![notification.userInfo[NSDeletedObjectsKey] containsObject:drawer.item])
				continue;
			
			[toRemove addObject:drawer];
			[self _unregisterDrawer:drawer];
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
		
		[self _notifyRedraw];
	}];
    
    drawStateNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GLLDrawStateChangedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        bzero(&self->state, sizeof(self->state));
        [self _notifyRedraw];
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
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[self _unregisterDrawer:drawer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"needsRedraw"])
	{
        if ([change[NSKeyValueChangeNewKey] boolValue]) {
            [self _notifyRedraw];
        }
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)drawWithNewStateShowingSelection:(BOOL)showSelection;
{
    bzero(&state, sizeof(state));
    [self drawShowingSelection:showSelection];
}

- (void)drawShowingSelection:(BOOL)showSelection;
{
    GLLBeginTiming("Draw/Solid");
	// 1st pass: Draw items that do not need blending. They use shaders without alpha test
	for (GLLItemDrawer *drawer in itemDrawers)
        [drawer drawSolidWithState:&state];
    GLLEndTiming("Draw/Solid");
    GLLBeginTiming("Draw/AlphaOp");
	
	// 2nd pass: Draw blended items, but only those pixels that are "almost opaque"
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, self.resourceManager.alphaTestPassGreaterBuffer);
	
	glEnable(GL_BLEND);
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawAlphaWithState:&state];
    
    GLLEndTiming("Draw/AlphaOp");
    GLLBeginTiming("Draw/AlphaTrans");
	// 3rd pass: Draw blended items, now only those things that are "mostly transparent".
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, self.resourceManager.alphaTestPassLessBuffer);
	
	glDepthMask(GL_FALSE);
	for (GLLItemDrawer *drawer in itemDrawers)
        [drawer drawAlphaWithState:&state];
    GLLEndTiming("Draw/AlphaTrans");
	
	if (showSelection)
    {
        GLLBeginTiming("Draw/Skel");
		glDisable(GL_DEPTH_TEST);
		glPointSize(10);
		[skeletonDrawer drawWithState:&state];
        glEnable(GL_DEPTH_TEST);
        GLLEndTiming("Draw/Skel");
	}
	
	// Special note: Ensure that depthMask is true before doing the next glClear. Otherwise results may be quite funny indeed.
	glDepthMask(GL_TRUE);
	glDisable(GL_BLEND);
}

- (NSManagedObjectContext *)managedObjectContext {
    return self.document.managedObjectContext;
}

#pragma mark - Selection

- (void)setSelectedBones:(NSArray *)selectedBones;
{
	skeletonDrawer.selectedBones = selectedBones;
	[self _notifyRedraw];
}
- (NSArray *)selectedBones
{
	return skeletonDrawer.selectedBones;
}

#pragma mark - Private methods

- (void)_addDrawerForItem:(GLLItem *)item;
{
	NSError *error = nil;
    NSDictionary<NSURL*,NSError*> *replacedTextures = @{};
    GLLItemDrawer *drawer = [[GLLItemDrawer alloc] initWithItem:item sceneDrawer:self replacedTextures:&replacedTextures error:&error];
	
	if (!drawer)
	{
		[NSApp presentError:error];
		if (item.objectID.isTemporaryID)
		{
			// Temporary ID means this was not loaded from a file. Get rid of it.
			[item.managedObjectContext deleteObject:item];
		}
		
		return;
    } else if (replacedTextures && replacedTextures.count > 0) {
        [self.document notifyTexturesNotLoaded:replacedTextures];
    }
	
	[itemDrawers addObject:drawer];
	[drawer addObserver:self forKeyPath:@"needsRedraw" options:NSKeyValueObservingOptionNew context:0];
}
- (void)_unregisterDrawer:(GLLItemDrawer *)drawer
{
	[drawer removeObserver:self forKeyPath:@"needsRedraw"];
	[drawer unload];
}
- (void)_notifyRedraw;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLLSceneDrawerNeedsUpdateNotification object:self];
}

@end
