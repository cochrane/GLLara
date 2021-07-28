//
//  GLLItemMesh+MeshExport.h
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

@class XnaLaraShaderDescription;

@interface GLLItemMesh (MeshExport)

- (XnaLaraShaderDescription *)shaderDescriptionError:(NSError *__autoreleasing*)error;
- (NSString *)genericItemNameForShaderDescription:(XnaLaraShaderDescription *)xnaLaraShaderDescription;
- (NSArray<NSURL *> *)textureUrlsForDescription:(XnaLaraShaderDescription *)xnaLaraShaderDescription;

- (NSString *)writeASCIIError:(NSError *__autoreleasing*)error;
- (NSData *)writeBinaryError:(NSError *__autoreleasing*)error;

@property (nonatomic, readonly) BOOL shouldExport;

@end
