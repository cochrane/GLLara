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

/*!
 * @abstract A render parameter whose value is a color.
 * @discussion These paramaters are new additions; XNALara has only float
 * parameters.
 */
@interface GLLColorRenderParameter : GLLRenderParameter

@property (nonatomic, retain) NSColor *value;

@property (nonatomic, readonly) NSData *uniformValue;

@end
