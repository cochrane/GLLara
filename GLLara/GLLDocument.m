//
//  GLLDocument.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocument.h"

#import "GLLDocumentWindowController.h"
#import "GLLItem.h"
#import "GLLModel.h"
#import "GLLRenderWindowController.h"
#import "GLLScene.h"
#import "GLLSceneDrawer.h"
#import "GLLView.h"

@interface GLLDocument ()
{
	GLLScene *scene;
	
	GLLDocumentWindowController *documentWindowController;
	GLLRenderWindowController *renderWindowController;
}

@end

@implementation GLLDocument

- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		
		scene = [[GLLScene alloc] init];
    }
    return self;
}

- (void)makeWindowControllers
{
	documentWindowController = [[GLLDocumentWindowController alloc] initWithScene:scene];
	[self addWindowController:documentWindowController];
	renderWindowController = [[GLLRenderWindowController alloc] initWithScene:scene];
	[self addWindowController:renderWindowController];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	// You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	// You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return YES;
}

@end
