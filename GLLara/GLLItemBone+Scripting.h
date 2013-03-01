//
//  GLLItemBone+Scripting.h
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemBone.h"

@interface GLLItemBone (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier;
- (NSString *)name;

@end
