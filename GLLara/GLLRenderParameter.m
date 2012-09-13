//
//  GLLRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderParameter.h"

#import "GLLItem.h"
#import "GLLMeshSettings.h"
#import "GLLMesh.h"
#import "GLLShaderDescriptor.h"

@implementation GLLRenderParameter

+ (NSSet *)keyPathsForValuesAffectingDescription
{
	return [NSSet setWithObject:@"name"];
}

@dynamic name;
@dynamic mesh;

- (GLLItem *)item
{
	return self.mesh.item;
}

- (GLLRenderParameterDescription *)parameterDescription
{
	return [self.mesh.mesh.shader descriptionForParameter:self.name];
}

- (NSData *)uniformValue
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
