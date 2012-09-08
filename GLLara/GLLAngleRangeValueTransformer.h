//
//  GLLAngleRangeValueTransformer.h
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Exactly what it says on the tin.
 * The idea is that rotations are stored from 0…2pi here, but for sliders, you really want -pi…+pi instead. This transformer solves that issue.
 */
@interface GLLAngleRangeValueTransformer : NSValueTransformer

@end
