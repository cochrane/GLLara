//
//  GLLRenderWindow.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindow.h"

#import "GLLView.h"

@implementation GLLRenderWindow

- (GLLCamera *)camera
{
	return self.renderView.camera;
}

@end
