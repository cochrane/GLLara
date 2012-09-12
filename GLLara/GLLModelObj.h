//
//  GLLModelObj.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModel.h"

@interface GLLModelObj : GLLModel

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing*)error;

@end
