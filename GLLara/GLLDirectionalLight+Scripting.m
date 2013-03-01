//
//  GLLDirectionalLight+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLDirectionalLight+Scripting.h"

#import <Cocoa/Cocoa.h>

#import "GLLDocument+Scripting.h"

@implementation GLLDirectionalLight (Scripting)

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
	NSUInteger indexForScripting = self.index - 1; // Index 0 is the ambient light, which is not present in the diffuseLights array.
	
	GLLDocument *document = self.document;
	return [[NSIndexSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:document.class] containerSpecifier:document.objectSpecifier key:@"diffuseLights" index:indexForScripting];
}

@end
