//
//  GLLItem+MeshExport.h
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

@interface GLLItem (MeshExport)

- (NSData *)writeBinary;
- (NSString *)writeASCII;

@end
