//
//  GLLItemMesh+MeshExport.h
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

@interface GLLItemMesh (MeshExport)

- (NSString *)genericItemNameError:(NSError *__autoreleasing*)error;

@property (nonatomic, readonly) NSArray *textureURLsInShaderOrder;

- (NSString *)writeASCIIError:(NSError *__autoreleasing*)error;
- (NSData *)writeBinaryError:(NSError *__autoreleasing*)error;

@end
