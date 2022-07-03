//
//  GLLVertexAttribAccessor.m
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import "GLLVertexAttrib.h"

@implementation GLLVertexAttrib

- (instancetype)initWithSemantic:(GLLVertexAttribSemantic)semantic layer:(NSInteger) layer format:(MTLVertexFormat) format;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _semantic = semantic;
    _layer = layer;
    _mtlFormat = format;
    
    return self;
}

- (NSUInteger)hash
{
    return _semantic ^ _layer ^ _mtlFormat;
}

- (BOOL)isEqualFormat:(GLLVertexAttrib *)format
{
    return format.semantic == self.semantic && format.layer == self.layer && format.mtlFormat == self.mtlFormat;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class])
        return NO;
    
    GLLVertexAttrib *format = (GLLVertexAttrib *) object;
    return format.semantic == self.semantic && format.layer == self.layer && format.mtlFormat == self.mtlFormat;
}

- (id)copy
{
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSInteger)sizeInBytes {
    switch (self.mtlFormat) {
        case MTLVertexFormatInvalid:
            return 0;
        case MTLVertexFormatChar:
        case MTLVertexFormatUChar:
        case MTLVertexFormatCharNormalized:
        case MTLVertexFormatUCharNormalized:
            return 1;
        case MTLVertexFormatChar2:
        case MTLVertexFormatUChar2:
        case MTLVertexFormatChar2Normalized:
        case MTLVertexFormatUChar2Normalized:
            return 2;
        case MTLVertexFormatChar3:
        case MTLVertexFormatUChar3:
        case MTLVertexFormatChar3Normalized:
        case MTLVertexFormatUChar3Normalized:
            return 3;
        case MTLVertexFormatChar4:
        case MTLVertexFormatUChar4:
        case MTLVertexFormatChar4Normalized:
        case MTLVertexFormatUChar4Normalized:
            return 4;
        case MTLVertexFormatShort:
        case MTLVertexFormatUShort:
        case MTLVertexFormatShortNormalized:
        case MTLVertexFormatUShortNormalized:
            return 2;
        case MTLVertexFormatShort2:
        case MTLVertexFormatUShort2:
        case MTLVertexFormatShort2Normalized:
        case MTLVertexFormatUShort2Normalized:
            return 4;
        case MTLVertexFormatShort3:
        case MTLVertexFormatUShort3:
        case MTLVertexFormatShort3Normalized:
        case MTLVertexFormatUShort3Normalized:
            return 6;
        case MTLVertexFormatShort4:
        case MTLVertexFormatUShort4:
        case MTLVertexFormatShort4Normalized:
        case MTLVertexFormatUShort4Normalized:
            return 8;
        case MTLVertexFormatHalf:
            return 2;
        case MTLVertexFormatHalf2:
            return 4;
        case MTLVertexFormatHalf3:
            return 6;
        case MTLVertexFormatHalf4:
            return 8;
        case MTLVertexFormatFloat:
            return 4;
        case MTLVertexFormatFloat2:
            return 8;
        case MTLVertexFormatFloat3:
            return 12;
        case MTLVertexFormatFloat4:
            return 16;
        case MTLVertexFormatInt:
        case MTLVertexFormatUInt:
            return 4;
        case MTLVertexFormatInt2:
        case MTLVertexFormatUInt2:
            return 8;
        case MTLVertexFormatInt3:
        case MTLVertexFormatUInt3:
            return 12;
        case MTLVertexFormatInt4:
        case MTLVertexFormatUInt4:
            return 16;
        case MTLVertexFormatInt1010102Normalized:
            return 4;
        case MTLVertexFormatUInt1010102Normalized:
            return 4;
        case MTLVertexFormatUChar4Normalized_BGRA:
            return 4;
    }
}

- (NSComparisonResult)compare:(GLLVertexAttrib *)other; {
    if (self.semantic < other.semantic) {
        return NSOrderedAscending;
    } else if (self.semantic > other.semantic) {
        return NSOrderedDescending;
    }
    
    if (self.layer < other.layer) {
        return NSOrderedAscending;
    } else if (self.layer > other.layer) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (NSInteger)identifier {
    // TODO Needs to match XnaLaraShader attributes
    switch (self.semantic) {
        case GLLVertexAttribPosition:
            return 0;
        case GLLVertexAttribNormal:
            return 1;
        case GLLVertexAttribColor:
            return 2;
        case GLLVertexAttribTexCoord0:
            if (self.layer == 0) {
                return 3;
            } else {
                return 4;
            }
        case GLLVertexAttribTangent0:
            return 5;
        case GLLVertexAttribBoneIndices:
            return 6;
        case GLLVertexAttribBoneWeights:
            return 7;
            
        default:
            return 100;
    }
    /*if (self.semantic == GLLVertexAttribTangent0 || self.semantic == GLLVertexAttribTexCoord0) {
        return self.semantic + 2 * self.layer;
    } else {
        return self.semantic;
    }*/
}

@end

