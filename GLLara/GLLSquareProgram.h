//
//  GLLSquareProgram.h
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLProgram.h"

/*!
 * @abstract Program that renders a screen-aligned square.
 * @discussion Needed for special effects.
 */
@interface GLLSquareProgram : GLLProgram

- (id)initWithResourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;

@end
