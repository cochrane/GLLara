//
//  GLLMeshSettingsViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSettingsViewController.h"

#import "GLLMesh.h"
#import "GLLMeshSettings.h"

@interface GLLMeshSettingsViewController ()

@end

@implementation GLLMeshSettingsViewController

+ (NSSet *)keyPathsForValuesAffectingStatusDisplay
{
	return [NSSet setWithObject:@"representedObject"];
}

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLMeshSettingsViewController" bundle:[NSBundle mainBundle]]))
		return nil;
	
	return self;
}

- (NSString *)statusDisplay
{
	if (!self.representedObject)
		return NSNoSelectionMarker;
	
	if (![self.representedObject isKindOfClass:[GLLMeshSettings class]])
		return NSNotApplicableMarker;
	
	GLLMeshSettings *settings = self.representedObject;
	
	return [NSString stringWithFormat:NSLocalizedString(@"%lu vertices, %lu faces, %lu textures", @"mesh settings view: Status bar"), settings.mesh.countOfVertices, settings.mesh.countOfElements / 3, settings.mesh.textures.count];
}

@end
