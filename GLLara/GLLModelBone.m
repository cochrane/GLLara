//
//  GLLModelBone.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelBone.h"

#import "GLLASCIIScanner.h"
#import "GLLModel.h"
#import "simd_matrix.h"
#import "TRInDataStream.h"
#import "LionSubscripting.h"

@implementation GLLModelBone

- (id)initWithModel:(GLLModel *)model;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	
	_parentIndex = UINT16_MAX;
	_parent = nil;
	_children = @[];
	
	_positionX = 0;
	_positionY = 0;
	_positionZ = 0;
	
	_positionMatrix = simd_mat_identity();
	_inversePositionMatrix = simd_mat_identity();
	
	_name = NSLocalizedString(@"Root bone", @"Only bone in a boneless format");
	
	return self;

}

- (id)initFromSequentialData:(id)stream partOfModel:(GLLModel *)model;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	
	_name = [stream readPascalString];
	_parentIndex = [stream readUint16];
	_positionX = [stream readFloat32];
	_positionY = [stream readFloat32];
	_positionZ = [stream readFloat32];
	
	_positionMatrix = simd_mat_positional(simd_make(_positionX, _positionY, _positionZ, 1.0f));
	_inversePositionMatrix = simd_mat_positional(simd_make(-_positionX, -_positionY, -_positionZ, 1.0f));
	
	return self;
}

#pragma mark - Finishing loading

- (void)setupParent
{
	_parent = self.parentIndex != UINT16_MAX ? self.model.bones[self.parentIndex] : nil;
	_children = [self.model.bones filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"parent == %@", self]];
}

@end
