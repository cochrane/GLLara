//
//  GLLDocument+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLDocument+Scripting.h"

#import <CoreData/CoreData.h>

@implementation GLLDocument (Scripting)

- (NSArray *)diffuseLights
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLDirectionalLight"];
	fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	return [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
}

- (NSArray *)items
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
	fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES] ];
	return [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
}

- (GLLAmbientLight *)ambientLight
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLAmbientLight"];
	NSArray *lights = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
	if (lights.count == 0) return nil;
	return [lights objectAtIndex:0];
}

@end
