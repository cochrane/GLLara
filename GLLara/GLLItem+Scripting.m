//
//  GLLItem+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem+Scripting.h"

#import <Cocoa/Cocoa.h>

#import "GLLDocument+Scripting.h"

@implementation GLLItem (Scripting)

- (GLLDocument *)document
{
	NSManagedObjectContext *context = self.managedObjectContext;
	for (GLLDocument *document in [[NSDocumentController sharedDocumentController] documents])
		if ([document.managedObjectContext isEqual:context])
			return document;
	
	return nil;
}

- (NSScriptObjectSpecifier *)objectSpecifier
{
	GLLDocument *document = self.document;
	if (!document) return nil;
	
	NSScriptClassDescription *containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[document class]];
	NSScriptObjectSpecifier *containerSpecifier = document.objectSpecifier;
	
	return [[NSNameSpecifier alloc] initWithContainerClassDescription:containerClassDescription containerSpecifier:containerSpecifier key:@"items" name:self.displayName];
}

- (NSArray *)scriptingBones;
{
	return self.bones.array;
}
- (NSArray *)scriptingMeshes;
{
	return self.meshes.array;
}

@end
