//
//  GLLItem+MeshExport.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem+MeshExport.h"

#import "GLLItemBone.h"
#import "GLLItemMesh+MeshExport.h"
#import "GLLModelBone.h"
#import "TROutDataStream.h"

@implementation GLLItem (MeshExport)

- (NSData *)writeBinary;
{
	TROutDataStream *stream = [[TROutDataStream alloc] init];
	
	[stream appendUint32:(uint32_t) self.bones.count];
	for (GLLItemBone *bone in self.bones)
		[stream appendData:[bone.bone writeBinary]];
	
	[stream appendUint32:(uint32_t) self.meshes.count];
	for (GLLItemMesh *mesh in self.meshes)
		[stream appendData:[mesh writeBinary]];
	
	return stream.data;
}
- (NSString *)writeASCII;
{
	NSMutableString *string = [NSMutableString string];
	
	[string appendFormat:@"%lu\n", self.bones.count];
	for (GLLItemBone *bone in self.bones)
		[string appendFormat:@"%@\n", [bone.bone writeASCII]];
	
	[string appendFormat:@"%lu\n", self.meshes.count];
	for (GLLItemMesh *mesh in self.meshes)
		[string appendFormat:@"%@\n", [mesh writeASCII]];
	
	return string;
}

@end
