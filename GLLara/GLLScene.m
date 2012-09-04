//
//  GLLScene.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLScene.h"

@implementation GLLScene

- (id)init
{
	if (!(self = [super init])) return nil;
	
	_items = [[NSMutableArray alloc] init];
	
	return self;
}

@end
