//
//  GLLItemBone+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemBone+Scripting.h"

#import "GLLItem+Scripting.h"
#import "GLLModelBone.h"

@implementation GLLItemBone (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier;
{
	return [[NSNameSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:self.item.class] containerSpecifier:self.item.objectSpecifier key:@"scriptingBones" name:self.name];
}

- (NSString *)name
{
	return self.bone.name;
}

@end
