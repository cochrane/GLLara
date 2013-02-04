//
//  GLLSkeletonProgram.h
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLProgram.h"

/*!
 * @abstract Program for rendering the skeleton when selecting.
 * @discussion This class loads the right shaders and sets up the attribute
 * locations.
 */
@interface GLLSkeletonProgram : GLLProgram

- (id)initWithResourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;

@end
