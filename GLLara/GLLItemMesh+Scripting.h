//
//  GLLItemMesh+Scripting.h
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

@interface GLLItemMesh (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier;

- (NSArray *)scriptingTextures;
- (NSArray *)scriptingRenderParameters;

@end
