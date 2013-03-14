//
//  GLLCamera+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 14.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLCamera+Scripting.h"

#import <Cocoa/Cocoa.h>

#import "GLLDocument+Scripting.h"
#import "GLLRenderWindow.h"

@implementation GLLCamera (Scripting)

- (GLLDocument *)document
{
	NSManagedObjectContext *context = self.managedObjectContext;
	for (GLLDocument *document in [[NSDocumentController sharedDocumentController] documents])
		if ([document.managedObjectContext isEqual:context])
			return document;
	
	return nil;
}

- (GLLRenderWindow *)window
{
	GLLDocument *document = self.document;
	for (GLLRenderWindow *window in document.renderWindows)
		if ([window.camera isEqual:self])
			return window;
	
	return nil;
}

- (NSScriptObjectSpecifier *)objectSpecifier;
{
	GLLRenderWindow *window = self.window;
	return [[NSPropertySpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:window.class] containerSpecifier:window.objectSpecifier key:@"camera"];
}

@end
