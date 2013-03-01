//
//  GLLDocument+Scripting.h
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLDocument.h"

@class GLLAmbientLight;

@interface GLLDocument (Scripting)

@property (nonatomic, retain, readonly) NSArray *diffuseLights;
@property (nonatomic, retain, readonly) NSArray *items;
@property (nonatomic, retain, readonly) NSArray *renderWindows;
@property (nonatomic, retain, readonly) GLLAmbientLight *ambientLight;

@end
