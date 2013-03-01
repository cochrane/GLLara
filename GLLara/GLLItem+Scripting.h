//
//  GLLItem+Scripting.h
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

@class GLLDocument;

@interface GLLItem (Scripting)

- (GLLDocument *)document;
- (NSScriptObjectSpecifier *)objectSpecifier;

- (NSArray *)scriptingBones;
- (NSArray *)scriptingMeshes;

@end
