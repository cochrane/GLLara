//
//  GLLRenderParameterDescription.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderParameterDescription.h"

@implementation GLLRenderParameterDescription

- (id)initWithPlist:(NSDictionary *)plist;
{
	if (!(self = [super init])) return nil;
	
	_min = [plist[@"min"] floatValue];
	_max = [plist[@"max"] floatValue];
	_localizedTitle = [[NSBundle mainBundle] localizedStringForKey:plist[@"title"] value:nil table:@"RenderParameters"];
	_localizedDescription = [[NSBundle mainBundle] localizedStringForKey:plist[@"description"] value:nil table:@"RenderParameters"];
	
	return self;
}

@end
