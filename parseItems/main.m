//
//  main.m
//  parseItems
//
//  Created by Torsten Kammer on 15.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSArray *parseNamesList(NSString *namesList)
{
	NSError *error = nil;
	id self = nil;
	SEL _cmd = nil;
	
	static NSRegularExpression *stringArrayExpression;
	if (!stringArrayExpression)
		stringArrayExpression = [NSRegularExpression regularExpressionWithPattern:@"\"([A-Za-z0-9_ ]+)\"" options:0 error:&error];
	NSAssert(stringArrayExpression, @"Couldn't compile string array expression: %@", error);

	
	NSArray *matches = [stringArrayExpression matchesInString:namesList options:0 range:NSMakeRange(0, namesList.length)];
	NSMutableArray *names = [[NSMutableArray alloc] initWithCapacity:matches.count];
	for (NSTextCheckingResult *match in matches)
		[names addObject:[namesList substringWithRange:[match rangeAtIndex:1]]];
	
	return [names copy];
}

static NSArray *parseFloatList(NSString *floatList)
{
	NSError *error = nil;
	id self = nil;
	SEL _cmd = nil;
	
	static NSRegularExpression *floatArrayExpression;
	if (!floatArrayExpression)
		floatArrayExpression = [NSRegularExpression regularExpressionWithPattern:@"([0-9\\.]+)f?" options:0 error:&error];
	NSAssert(floatArrayExpression, @"Couldn't compile float array expression: %@", error);
	
	NSArray *matches = [floatArrayExpression matchesInString:floatList options:0 range:NSMakeRange(0, floatList.length)];
	NSMutableArray *numbers = [[NSMutableArray alloc] initWithCapacity:matches.count];
	for (NSTextCheckingResult *match in matches)
	{
		NSString *number = [floatList substringWithRange:[match rangeAtIndex:1]];
		[numbers addObject:@(number.doubleValue)];
	}
	
	return [numbers copy];
}

static NSString *renderParameterNameForIndexInGroup(NSUInteger index, NSString *meshName, NSDictionary *meshGroupNames)
{
	// See "Render parameters.md" for an explanation
	
	BOOL isMetallic = false;
	
	if (meshName)
	{
		if ([meshGroupNames[@"MeshGroup26"] containsObject:meshName])
			isMetallic = true;
		else if ([meshGroupNames[@"MeshGroup27"] containsObject:meshName])
			isMetallic = true;
		else if ([meshGroupNames[@"MeshGroup28"] containsObject:meshName])
			isMetallic = true;
		else if ([meshGroupNames[@"MeshGroup29"] containsObject:meshName])
			isMetallic = true;
	}
	
	switch (index)
	{
		case 0:
			return isMetallic ? @"reflectionAmount" : @"bumpSpecularAmount";
			break;
		case 1:
			return isMetallic ? @"bumpSpecularAmount" : @"bump1UVScale";
			break;
		case 2:
			return isMetallic ? @"bumpUVScale" : @"bump2UVScale";
			break;
		default:
			return [NSString stringWithFormat:@"unknown%lu", index];
	}
}

static NSDictionary *parseRenderParameters(NSString *params, NSString *meshname, NSDictionary *meshGroups)
{
	NSArray *values = parseFloatList(params);
	
	NSMutableDictionary *fullValues = [[NSMutableDictionary alloc] initWithCapacity:values.count];
	for (NSUInteger i = 0; i < values.count; i++)
		fullValues[renderParameterNameForIndexInGroup(i, meshname, meshGroups)] = values[i];
	
	return [fullValues copy];
}

int main(int argc, const char * argv[])
{
	id self = nil;
	SEL _cmd = NULL;
	
	@autoreleasepool {
		NSAssert(argc == 3, @"Usage: %s infile outfile", argv[0]);
		
		NSString *inPath = [NSString stringWithCString:argv[1] encoding:NSMacOSRomanStringEncoding];
		NSString *outPath =[NSString stringWithCString:argv[2] encoding:NSMacOSRomanStringEncoding];
		
		NSError *error = nil;
		NSString *itemFile = [NSString stringWithContentsOfFile:inPath encoding:NSUTF8StringEncoding error:&error];
		NSRange full = NSMakeRange(0, itemFile.length);
		NSAssert(itemFile, @"not found file: %@", error);
		
		NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
		
		// Find base
		NSRegularExpression *className = [NSRegularExpression regularExpressionWithPattern:@"public class [A-Za-z]+ : ([A-Za-z]+)" options:0 error:&error];
		NSAssert(itemFile, @"couldn't compile regexp: %@", error);
		
		NSTextCheckingResult *classNameMatch = [className firstMatchInString:itemFile options:0 range:full];
		NSString *baseClass = [itemFile substringWithRange:[classNameMatch rangeAtIndex:1]];
		if ([baseClass isEqual:@"Item"])
			data[@"base"] = @"xnaLaraDefault";
		else
			data[@"base"] = baseClass.lowercaseString;
		
		// Find mesh groups
		NSRegularExpression *meshGroupRegexp = [NSRegularExpression regularExpressionWithPattern:@"model\\.DefineMeshGroup\\(MeshGroupNames\\.([A-Za-z0-9]+), ((?:\"[a-zA-Z0-9]+\",? ?)+)\\);" options:0 error:&error];
		NSAssert(meshGroupRegexp, @"couldn't compile regexp: %@", error);
		
		NSMutableDictionary *meshGroups = [[NSMutableDictionary alloc] init];
		NSArray *meshGroupMatches = [meshGroupRegexp matchesInString:itemFile options:0 range:full];
		for (NSTextCheckingResult *result in meshGroupMatches)
		{
			NSString *groupName = [itemFile substringWithRange:[result rangeAtIndex:1]];
			NSString *meshNameList = [itemFile substringWithRange:[result rangeAtIndex:2]];
			meshGroups[groupName] = parseNamesList(meshNameList);
		}
		data[@"meshGroupNames"] = [meshGroups copy];
		
		// Find default render parameters
		NSRegularExpression *defaultParamsRegexp = [NSRegularExpression regularExpressionWithPattern:@"mesh\\.RenderParams = new object\\[\\] \\{ ((?:[0-9.]+f,?  ?)+)\\};" options:0 error:&error];
		NSAssert(defaultParamsRegexp, @"couldn't compile regexp: %@", error);
		
		NSTextCheckingResult *defaultParamsMatch = [defaultParamsRegexp firstMatchInString:itemFile options:0 range:full];
		if (defaultParamsMatch && [defaultParamsMatch rangeAtIndex:0].location != NSNotFound)
		{
			NSString *parameterValues = [itemFile substringWithRange:[defaultParamsMatch rangeAtIndex:1]];
			data[@"defaultRenderParameters"] = parseRenderParameters(parameterValues, nil, nil);
		}
		
		// Find render parameters
		NSRegularExpression *renderParamsRegexp = [NSRegularExpression regularExpressionWithPattern:@"model\\.GetMesh\\(\"([a-zA-Z0-9]+)\"\\).RenderParams = new object\\[\\] \\{ ((?:[0-9.]+f,?  ?)+)\\}" options:0 error:&error];
		NSAssert(renderParamsRegexp, @"couldn't compile regexp: %@", error);
		
		NSArray *renderParameterMatches = [renderParamsRegexp matchesInString:itemFile options:0 range:full];
		NSMutableDictionary *renderParameters = [[NSMutableDictionary alloc] initWithCapacity:renderParameterMatches.count];
		for (NSTextCheckingResult *match in renderParameterMatches)
		{
			NSString *meshName = [itemFile substringWithRange:[match rangeAtIndex:1]];
			NSString *parameterValues = [itemFile substringWithRange:[match rangeAtIndex:2]];
			renderParameters[meshName] = parseRenderParameters(parameterValues, meshName, data[@"meshGroupNames"]);
		}
		data[@"renderParameters"] = [renderParameters copy];
		
		// Find camera targets
		NSRegularExpression *cameraTargetsRegexp = [NSRegularExpression regularExpressionWithPattern:@"AddCameraTarget\\(\"([a-z ]+)\", (\"[a-zA-Z0-9_ ]+\",? ?)\\);" options:0 error:&error];
		NSAssert(cameraTargetsRegexp, @"Couldn't compile regexp: %@", error);
		
		NSMutableDictionary *cameraTargets = [[NSMutableDictionary alloc] init];
		NSArray *cameraTargetMatches = [cameraTargetsRegexp matchesInString:itemFile options:0 range:full];
		for (NSTextCheckingResult *result in cameraTargetMatches)
		{
			NSString *targetName = [itemFile substringWithRange:[result rangeAtIndex:1]];
			NSString *targetBoneList = [itemFile substringWithRange:[result rangeAtIndex:2]];
			cameraTargets[targetName] = parseNamesList(targetBoneList);
		}
		data[@"cameraTargets"] = [cameraTargets copy];
		
		// Write out
		[data writeToFile:outPath atomically:NO];
	}
    return 0;
}

