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
#import "TROutDataStream.h"
#import "LionSubscripting.h"

@implementation GLLModelBone

@dynamic hasParent;

- (id)init;
{
	if (!(self = [super init])) return nil;
	
	_parentIndex = UINT16_MAX;
	
	_positionX = 0;
	_positionY = 0;
	_positionZ = 0;
	
	_positionMatrix = simd_mat_identity();
	_inversePositionMatrix = simd_mat_identity();
	
	_name = NSLocalizedString(@"Root bone", @"Only bone in a boneless format");
	
	return self;

}

- (id)initFromSequentialData:(id)stream partOfModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	if (![stream isValid])
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
				   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off in the middle of the bones section. Maybe it is damaged?", @"Premature end of file error")
					  }];
		return nil;
	}
		
	_name = [stream readPascalString];
	_parentIndex = [stream readUint16];
	_positionX = [stream readFloat32];
	_positionY = [stream readFloat32];
	_positionZ = [stream readFloat32];
	
	if (![stream isValid])
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
				   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off in the middle of the bones section. Maybe it is damaged?", @"Premature end of file error")
					  }];
		return nil;
	}
	
	_positionMatrix = simd_mat_positional(simd_make(_positionX, _positionY, _positionZ, 1.0f));
	_inversePositionMatrix = simd_mat_positional(simd_make(-_positionX, -_positionY, -_positionZ, 1.0f));
	
	return self;
}

- (BOOL)hasParent
{
    return self.parentIndex != 0xFFFF;
}

#pragma mark - Export

- (NSString *)writeASCII;
{
	NSMutableString *result = [NSMutableString string];
	
	[result appendFormat:@"%@\n", self.name];
	[result appendFormat:@"%d\n", self.parentIndex != NSNotFound ? (int) self.parentIndex : -1];
	[result appendFormat:@"%f %f %f\n", self.positionX, self.positionY, self.positionZ];
	
	return [result copy];
}

- (NSData *)writeBinary;
{
	TROutDataStream *stream = [[TROutDataStream alloc] init];
	
	[stream appendPascalString:self.name];
	[stream appendUint16:(uint16_t) self.parentIndex];
	[stream appendFloat32:self.positionX];
	[stream appendFloat32:self.positionY];
	[stream appendFloat32:self.positionZ];
	
	return stream.data;
}

@end
