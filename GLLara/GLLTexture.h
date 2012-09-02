//
//  GLLTexture.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGL/gltypes.h>

@interface GLLTexture : NSObject

- (id)initWithFile:(NSURL *)fileURL;

- (void)unload;

@property (nonatomic, assign, readonly) GLuint name;

@end
