//
//  GLLAddModelScriptCommand.m
//  GLLara
//
//  Created by Torsten Kammer on 14.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLAddModelScriptCommand.h"

#import "GLLDocument.h"

@implementation GLLAddModelScriptCommand

- (id)performDefaultImplementation
{
	NSDictionary *evaluatedArguments = self.evaluatedArguments;
	NSURL *modelURL = evaluatedArguments[@""];
	GLLDocument *document = evaluatedArguments[@"DocumentToAddTo"];
	
	NSError *error = nil;
	GLLItem *item = [document addModelAtURL:modelURL error:&error];
	if (!item)
	{
		self.scriptErrorString = error.localizedDescription;
		return nil;
	}
	
	return item;
}

@end
