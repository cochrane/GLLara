//
//  GLLItem+Export.m
//  GLLara
//
//  Created by Torsten Kammer on 15.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem+Export.h"

#import "GLLItem+OBJExport.h"
#import "GLLItem+MeshExport.h"
#import "GLLItemMesh.h"
#import "NSArray+Map.h"

@implementation GLLItem (Export)

+ (BOOL)exportType:(GLLItemExportType)exportType supportsPoseType:(GLLItemExportPoseType)poseType;
{
	if (exportType == GLLItemExportTypeOBJ || exportType == GLLItemExportTypeOBJWithVertexColors)
		if (poseType == GLLDefaultPosePoseable)
			return NO;
	
	return YES;
}

- (NSArray *)exportAsType:(GLLItemExportType)type targetLocation:(NSURL *)targetLocation packageWithTextures:(BOOL)packageWithTextures poseType:(GLLItemExportPoseType)poseType error:(NSError *__autoreleasing*)error;
{
	// Prepare model files
	NSArray *modelFileWrappers = nil;
	if (type == GLLItemExportTypeOBJ || type == GLLItemExportTypeOBJWithVertexColors)
	{
		// Check whether this combination of value is legal
		if (poseType == GLLDefaultPosePoseable)
		{
			if (error)
				*error = [NSError errorWithDomain:@"GLLExporting" code:1 userInfo:@{
						NSLocalizedDescriptionKey: NSLocalizedString(@"OBJ files cannot be exported as poseable.", @"obj not poseable - heading"),
		   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Use another format or export as static.", @"obj not poseable - main text")
						  }];
			return nil;
		}
		
		// Prepare file names
		NSString *objFilename = targetLocation.lastPathComponent;
		if (packageWithTextures && objFilename.pathExtension.length == 0)
			objFilename = [objFilename stringByAppendingPathExtension:@"obj"];
		NSString *mtlFilename = [[objFilename stringByDeletingPathExtension] stringByAppendingPathExtension:@"mtl"];
		
		// Base URL for exporting. Not needed if textures are exported, too.
		NSURL *baseLocation = packageWithTextures ? nil : targetLocation;
		
		// Export data
		NSString *objString = [self objStringForFilename:objFilename withTransform:poseType == GLLCurrentPoseStatic withColor:type == GLLItemExportTypeOBJWithVertexColors error:error];
		if (!objString)
			return nil;
		
		NSString *mtlString = [self mtlStringForLocation:baseLocation error:error];
		if (!mtlString)
			return nil;
		
		// Prepare file wrappers
		NSFileWrapper *objWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[objString dataUsingEncoding:NSUTF8StringEncoding]];
		objWrapper.filename = objFilename;
		objWrapper.preferredFilename = objFilename;
		NSFileWrapper *mtlWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[mtlString dataUsingEncoding:NSUTF8StringEncoding]];
		mtlWrapper.filename = mtlFilename;
		mtlWrapper.preferredFilename = mtlFilename;
		
		modelFileWrappers = @[ objWrapper, mtlWrapper ];
	}
	else if (type == GLLItemExportTypeXNALara)
	{
		// Find file names
		NSString *binaryFileName = packageWithTextures ? @"generic_item.mesh" : targetLocation.lastPathComponent;
		
		// Get as .mesh.ascii. This should always work if an export is possible.
		NSString *meshASCIIString = [self writeASCIIError:error];
		NSData *meshASCIIData = [meshASCIIString dataUsingEncoding:NSUTF8StringEncoding];
		if (!meshASCIIData) return nil;
		NSFileWrapper *meshASCIIWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:meshASCIIData];
		meshASCIIWrapper.filename = [binaryFileName stringByAppendingPathExtension:@"ascii"];
		meshASCIIWrapper.preferredFilename = [binaryFileName stringByAppendingPathExtension:@"ascii"];
		
		// Get as .mesh. This may fail if the file has no tangents, but since
		// .mesh.ascii exists, this can be accepted.
		NSData *meshBinaryData = [self writeBinaryError:NULL];
		if (!meshBinaryData)
		{
			modelFileWrappers = @[ meshASCIIWrapper ];
		}
		else
		{
			NSFileWrapper *meshBinaryWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:meshBinaryData];
			meshBinaryWrapper.filename = binaryFileName;
			meshBinaryWrapper.preferredFilename = binaryFileName;
			modelFileWrappers = @[ meshBinaryWrapper, meshASCIIWrapper ];
		}
	}
	else
		[NSException raise:NSInternalInconsistencyException format:@"export type %lu is not known", type];
	
	// Add textures (if necessary) and return
	if (packageWithTextures)
	{
		// Prepare directory file wrapper and add models.
		NSFileWrapper *directory = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
		for (NSFileWrapper *wrapper in modelFileWrappers)
			[directory addFileWrapper:wrapper];
		
		// Add textures. Keep track of ones that were already added.
		NSMutableSet *alreadyAdded = [NSMutableSet set];
		for (GLLItemMesh *mesh in [self valueForKeyPath:@"meshes"])
		{
			for (NSURL *textureURL in [mesh valueForKeyPath:@"textures.textureURL.absoluteURL"])
			{
				if ([alreadyAdded containsObject:textureURL]) continue;
				[alreadyAdded addObject:textureURL];
				
				NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:textureURL options:NSFileWrapperReadingImmediate error:error];
				if (!wrapper) return nil;
				
				[directory addFileWrapper:wrapper];
			}
		}
		
		// Cleanup
		directory.filename = targetLocation.lastPathComponent;
		return @[ directory ];
	}
	else
		return modelFileWrappers;
}

@end
