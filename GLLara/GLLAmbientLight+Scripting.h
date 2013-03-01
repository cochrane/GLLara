//
//  GLLAmbientLight+Scripting.h
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLAmbientLight.h"

@class GLLDocument;

@interface GLLAmbientLight (Scripting)

- (GLLDocument *)document;
- (NSScriptObjectSpecifier *)objectSpecifier;

@end
