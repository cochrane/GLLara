//
//  GLLTextureDescription.m
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLTextureDescription.h"

@implementation GLLTextureDescription

- (id)initWithPlist:(NSDictionary *)plist;
{
	if (!(self = [super init])) return nil;
	
	_localizedTitle = [[NSBundle mainBundle] localizedStringForKey:plist[@"title"] value:nil table:@"Textures"];
	_localizedDescription = [[NSBundle mainBundle] localizedStringForKey:plist[@"description"] value:nil table:@"Textures"];
		
	return self;
}

@end
