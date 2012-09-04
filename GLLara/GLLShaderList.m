//
//  GLLShaderList.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLShaderList.h"

@interface GLLShaderList ()
{
	NSDictionary *shaderList;
}

@end

static GLLShaderList *defaultShaderList;

@implementation GLLShaderList

+ (id)defaultShaderList;
{
	if (!defaultShaderList)
	{
		NSURL *defaultShaderListURL = [[NSBundle mainBundle] URLForResource:@"shaders" withExtension:@"plist"];
		NSError *error = nil;
		defaultShaderList = [[self alloc] initWithPlist:[NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:defaultShaderListURL] options:NSPropertyListImmutable format:NULL error:&error]];
		NSAssert(defaultShaderList, @"Couldn't load shader list. Reading error: %@", error);
	}
	return defaultShaderList;
}

- (id)initWithPlist:(NSDictionary *)propertyList;
{
	if (!(self = [super init])) return nil;
	
	shaderList = [propertyList copy];
	
	return self;
}

- (NSArray *)shaderNames
{
	return shaderList.allKeys;
}

- (NSString *)vertexShaderForName:(NSString *)shaderName;
{
	return shaderList[shaderName][@"vertex"];
}
- (NSString *)geometryShaderForName:(NSString *)shaderName;
{
	return shaderList[shaderName][@"geometry"];
}
- (NSString *)fragmentShaderForName:(NSString *)shaderName;
{
	return shaderList[shaderName][@"fragment"];
}
- (NSArray *)renderParameterNamesForName:(NSString *)shaderName;
{
	return shaderList[shaderName][@"parameters"];
}

@end
