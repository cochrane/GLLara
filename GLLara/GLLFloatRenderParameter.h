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


@interface GLLFloatRenderParameter : GLLRenderParameter

@property (nonatomic) float value;

@property (nonatomic, readonly) NSData *uniformValue;

@end
