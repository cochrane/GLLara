//
//  GLLRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderParameter.h"

#import "GLLMesh.h"
#import "GLLMeshSettings.h"
#import "GLLModel.h"
#import "GLLModelParams.h"
#import "GLLRenderParameterDescription.h"

@implementation GLLRenderParameter

+ (NSSet *)keyPathsForValuesAffectingDescription
{
	return [NSSet setWithObject:@"name"];
}

@dynamic name;
@dynamic mesh;

- (GLLRenderParameterDescription *)parameterDescription
{
	// That's ugly.
	return [self.mesh.mesh.model.parameters descriptionForParameter:self.name];
}

- (NSData *)uniformValue
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
