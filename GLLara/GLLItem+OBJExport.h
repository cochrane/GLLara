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

/*!
 * @abstract Generates the export data for this object as OBJ.
 * @param name The name of the file. Used to refer to the mtllib file (which
 * will get the same name, but with the path extension replaced with .mtl).
 * @param transform Whether the object should be exported in the current
 * pose or default.
 * @param color Whether vertex color elements (vc) should be included, and
 * corresponding faces. This is a non-standard extension and could really
 * confuse most programs.
 * @param error Out parameter for errors. Can be NULL.
 * @result The file contents, or nil if an error occured.
 */
- (NSString *)objStringForFilename:(NSString *)name withTransform:(BOOL)transform withColor:(BOOL)color error:(NSError *__autoreleasing*)error;
/*!
 * @abstract Generates the export data for this object's graphic settings.
 * @param location The location, used for relative file paths. If set to nil,
 * then only filenames are included, with no path.
 * @param error Out parameter for errors. Can be NULL.
 * @result The file contents, or nil if an error occured.
 */
- (NSString *)mtlStringForLocation:(NSURL *)location error:(NSError *__autoreleasing*)error;

/*!
 * @abstract Generates the export data for this object as OBJ and writes it
 * to a file.
 * @param location The location to write to, also used for relative file paths.
 * @param transform Whether the object should be exported in the current
 * pose or default.
 * @param color Whether vertex color elements (vc) should be included, and
 * corresponding faces. This is a non-standard extension and could really
 * confuse most programs.
 * @param error Out parameter for errors. Can be NULL.
 * @result Whether the file could be written.
 */
- (BOOL)writeOBJToLocation:(NSURL *)location withTransform:(BOOL)transform withColor:(BOOL)color error:(NSError *__autoreleasing*)error;
/*!
 * @abstract Generates the export data for this object's graphic settings and
 * writes them to a file.
 * @param location The location to write to, also used for relative file paths.
 * @param error Out parameter for errors. Can be NULL.
 * @result Whether the file could be written.
 */
- (BOOL)writeMTLToLocation:(NSURL *)location error:(NSError *__autoreleasing*)error;

@end
