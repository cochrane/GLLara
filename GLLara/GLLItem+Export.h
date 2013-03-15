//
//  GLLItem+Export.h
//  GLLara
//
//  Created by Torsten Kammer on 15.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

typedef enum GLLItemExportType : NSUInteger {
	GLLItemExportTypeOBJ,
	GLLItemExportTypeOBJWithVertexColors,
	GLLItemExportTypeXNALara
} GLLItemExportType;

typedef enum GLLItemExportPoseType : NSUInteger {
	GLLCurrentPoseStatic,
	GLLDefaultPoseStatic,
	GLLDefaultPosePoseable
} GLLItemExportPoseType;

@interface GLLItem (Export)

/*!
 * @abstract Exports the selected item with all current settings.
 * @discussion This will return one or more file wrappers with the chosen
 * name and appropriate extensions.
 * @param type The type to export as. Not all types support all features.
 * @param targetLocation Where the file should be written to. This is necessary
 * for file types that support relative paths. It will also be used to set the
 * filename(s) of the resulting file wrappers. It should include the default
 * extension (.mesh for XNALara format, .obj for OBJ) unless
 * <code>packageWithTexture</code> is set to <code>YES</code>.
 * @param packageWithTextures If this is set to <code>YES</code>, then the
 * textures get added to the directory. Otherwise, the exported files will
 * only refer to them as if they were.
 * @param poseType How the poses are to be exported. Not all combinations are
 * possible with all types. In particular, OBJ doesn't support poseable export.
 * @param error A pointer to an error. If exporting isn't possible for some
 * reason, this method returns nil and fills this pointer with an error
 * description (unless this pointer is <code>NULL</code>).
 * @result Depending on the chosen settings, either two file wrappers (.obj and
 * .mtl or .mesh and .mesh.ascii), one (in case .mesh can't be generated) or one
 * directory wrapper (if images are included). The name will be filename, plus
 * the appropriate extensions. If there's an error, returns nil.
 */
- (NSArray *)exportAsType:(GLLItemExportType)type targetLocation:(NSURL *)targetLocation packageWithTextures:(BOOL)packageWithTextures poseType:(GLLItemExportPoseType)poseType error:(NSError *__autoreleasing*)error;

/*!
 * Whether a given export type supports a given pose type.
 */
+ (BOOL)exportType:(GLLItemExportType)exportType supportsPoseType:(GLLItemExportPoseType)poseType;

@end
