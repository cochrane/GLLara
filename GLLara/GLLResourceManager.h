//
//  GLLResourceManager.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLProgram;
@class GLLTexture;
@class GLLModel;
@class GLLModelDrawer;

@interface GLLResourceManager : NSObject

- (GLLModelDrawer *)drawerForModel:(GLLModel *)model;
- (GLLProgram *)programForName:(NSString *)programName baseURL:(NSURL *)baseURL;
- (GLLTexture *)textureForName:(NSString *)textureName baseURL:(NSURL *)baseURL;
- (NSArray *)texturesForNames:(NSArray *)textureNames baseURL:(NSURL *)baseURL;

@end
