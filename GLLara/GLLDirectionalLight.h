//
//  GLLLight.h
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "simd_types.h"

#import "GLLRenderParameters.h"

/*!
 * @abstract A directional light.
 * @discussion Each scene will have three that can be enabled or disabled. The
 * entity stores all the relevant information and can put them in a format
 * useable by the shaders.
 */
@interface GLLDirectionalLight : NSManagedObject

@property (nonatomic) BOOL isEnabled;
@property (nonatomic) NSUInteger index;
@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic, retain) NSColor *diffuseColor;
@property (nonatomic, retain) NSColor *specularColor;

@property (nonatomic, readonly) struct GLLLightBuffer uniformBlock;

@end
