//
//  GLLItem+OBJExport.h
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

/*!
 * @abstract Methods for exporting a posed item to an OBJ file.
 */
@interface GLLItem (OBJExport)

@property (nonatomic, readonly) BOOL willLoseDataWhenConvertedToOBJ;
- (BOOL)writeOBJToLocation:(NSURL *)location withTransform:(BOOL)transform withColor:(BOOL)color error:(NSError *__autoreleasing*)error;
- (BOOL)writeMTLToLocation:(NSURL *)location error:(NSError *__autoreleasing*)error;

@end
