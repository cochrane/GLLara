//
//  GLLItemMesh+MeshExport.h
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

@interface GLLItemMesh (MeshExport)

@property (nonatomic, readonly) NSString *genericItemName;
@property (nonatomic, readonly) NSArray *textureURLsInShaderOrder;

- (NSString *)writeASCII;
- (NSData *)writeBinary;

@end
