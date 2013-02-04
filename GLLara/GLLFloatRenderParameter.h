//
//  GLLFloatRenderParameter.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GLLRenderParameter.h"

/*!
 * @abstract A render parameter whose value is a single real number.
 * @discussion This includes all XNALara-specific render parameters, but also
 * a few added myself.
 */
@interface GLLFloatRenderParameter : GLLRenderParameter

@property (nonatomic) float value;

@property (nonatomic, readonly) NSData *uniformValue;

@end
