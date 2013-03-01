//
//  GLLAmbientLight+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLAmbientLight+Scripting.h"

#import <Cocoa/Cocoa.h>

#import "GLLDocument+Scripting.h"

@implementation GLLAmbientLight (Scripting)

- (GLLDocument *)document
{
	NSManagedObjectContext *context = self.managedObjectContext;
	for (GLLDocument *document in [[NSDocumentController sharedDocumentController] documents])
		if ([document.managedObjectContext isEqual:context])
			return document;
	
	return nil;
}

- (NSScriptObjectSpecifier *)objectSpecifier;
{
	GLLDocument *document = self.document;
	return [[NSPropertySpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:document.class] containerSpecifier:document.objectSpecifier key:@"ambientLight"];
}

@end
