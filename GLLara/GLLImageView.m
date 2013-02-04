//
//  GLLImageView.m
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLImageView.h"

@implementation GLLImageView

+ (void)initialize
{
	[self exposeBinding:@"imageURL"];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	self.imageURL = [NSURL URLFromPasteboard:sender.draggingPasteboard];
	
	[super concludeDragOperation:sender];
}

- (void)setImageURL:(NSURL *)imageURL
{
	_imageURL = imageURL;
	self.image = [[NSImage alloc] initByReferencingURL:imageURL];
}

@end
