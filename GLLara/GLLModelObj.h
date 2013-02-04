//
//  GLLModelObj.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModel.h"

/*!
 * @abstract A Model read from an OBJ file.
 * @discussion These models will always have exactly one bone, and one mesh for
 * every material used. XNALara-specific extensions and simplifications are
 * supported, too.
 */
@interface GLLModelObj : GLLModel

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing*)error;

@end
