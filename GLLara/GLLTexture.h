//
//  GLLTexture.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGL/gltypes.h>

/*!
 * @abstract A texture.
 * @discussion Nothing much to see here. This uses hand-written code to load DDS files and ImageIO to load everything else, and vImage to unpremultiply whatever comes from ImageIO.
 */
@interface GLLTexture : NSObject

- (id)initWithData:(NSData *)data;

- (void)unload;

@property (nonatomic, assign, readonly) GLuint textureID;

@end
