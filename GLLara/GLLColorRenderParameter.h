//
//  GLLColorRenderParameter.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GLLRenderParameter.h"


@interface GLLColorRenderParameter : GLLRenderParameter

@property (nonatomic, retain) NSColor *value;

@property (nonatomic, readonly) NSData *uniformValue;

@end
