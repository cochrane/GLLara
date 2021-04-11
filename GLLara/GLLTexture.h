//
//  GLLTexture.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGL/gltypes.h>

extern NSString *GLLTextureChangeNotification;

/*!
 * @abstract A texture.
 * @discussion Nothing much to see here. This uses hand-written code to load DDS files and ImageIO to load everything else, and vImage to unpremultiply whatever comes from ImageIO.
 */
@interface GLLTexture : NSObject <NSFilePresenter>

- (id)initWithURL:(NSURL *)url error:(NSError *__autoreleasing *)error __attribute__((nonnull(1)));

/*!
 * @abstract Load from data (assuming this is part of some other file)
 * @discussion Intended in particular for glTF (binary glTF and data URIs in it),
 * where the file may start sort of randomly, and where updating the texture
 * independent of the model is not possible anyway.
 * @param data The data to load
 * @param url The URL to use for error messages
 * @param error Output error
 */
- (id)initWithData:(NSData *)data sourceURL:(NSURL *)url error:(NSError *__autoreleasing *)error __attribute__((nonnull(1)));

- (void)unload;

@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;

@property (nonatomic) NSURL *url;
@property (nonatomic, assign, readonly) GLuint textureID;

@end
