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

@implementation GLLModelBone

- (instancetype)initWithModel:(GLLModel *)model;
{
    if (!(self = [super init])) return nil;
    
    _model = model;
    
    _parentIndex = UINT16_MAX;
    _children = [NSMutableArray array];
    
    _positionX = 0;
    _positionY = 0;
    _positionZ = 0;
    
    _positionMatrix = matrix_identity_float4x4;
    _inversePositionMatrix = matrix_identity_float4x4;
    
    _name = NSLocalizedString(@"Root bone", @"Only bone in a boneless format");
    
    return self;
    
}

- (instancetype)initFromSequentialData:(id)stream partOfModel:(GLLModel *)model atIndex:(NSUInteger)index error:(NSError *__autoreleasing*)error;
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
    
    _model = model;
    
    _name = [stream readPascalString];
    _parentIndex = [stream readUint16];
    _positionX = [stream readFloat32];
    _positionY = [stream readFloat32];
    _positionZ = [stream readFloat32];
    
    _children = [NSMutableArray array];
    
    if (_parentIndex == index) {
        if ([_name hasPrefix:@"unused"]) {
            // Apparently that's a thing that people do. Create unused bones with themselves set as parent. Why, though? What's wrong with them?
            NSLog(@"Bone %lu (named \"%@\") has itself as parent. Unused, so set as root bone. Why do people do that?", index, _name);
            _parentIndex = UINT16_MAX;
        } else {
            if (error)
                *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_CircularReference userInfo:@{
                                                                                                                                    NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Bone \"%@\" has itself as an ancestor.", @"Found a circle in the bone relationships."), self.name],
                                                                                                                                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The bones would form an infinite loop.", @"Found a circle in a bone relationship")}];
            return nil;
        }
    }
    
    if (![stream isValid])
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off in the middle of the bones section. Maybe it is damaged?", @"Premature end of file error")
                                                                                                                                 }];
        return nil;
    }
    
    _positionMatrix = simd_mat_positional(simd_make_float4(_positionX, _positionY, _positionZ, 1.0f));
    _inversePositionMatrix = simd_mat_positional(simd_make_float4(-_positionX, -_positionY, -_positionZ, 1.0f));
    
    return self;
}

- (GLLModelBone *)parent
{
    if (self.parentIndex >= self.model.bones.count) return nil;
    return self.model.bones[self.parentIndex];
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
