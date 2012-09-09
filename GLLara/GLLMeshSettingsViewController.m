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

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLMeshSettingsViewController" bundle:[NSBundle mainBundle]]))
		return nil;
	
	return self;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [tableView makeViewWithIdentifier:@"RenderParameterView" owner:self];
}

@end
