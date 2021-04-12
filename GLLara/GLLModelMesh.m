//
//  GLLModelMesh.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh.h"

#import "GLLASCIIScanner.h"
#import "GLLModel.h"
#import "GLLTiming.h"
#import "GLLVertexAttribAccessor.h"
#import "GLLVertexAttribAccessorSet.h"
#import "GLLVertexFormat.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

#import "GLLara-Swift.h"

float vec_dot(const float *a, const float *b)
{
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
}
void vec_normalize(float *vec)
{
    float length = sqrtf(vec_dot(vec, vec));
    if (length == 0.0f) return;
    vec[0] /= length;
    vec[1] /= length;
    vec[2] /= length;
}
void vec_addTo(float *a, const float *b)
{
    a[0] += b[0];
    a[1] += b[1];
    a[2] += b[2];
}

@interface GLLModelMesh()

// The vertex format for the things that are in the file
- (GLLVertexFormat *)fileVertexFormat;

// Generates the vertex data accessors for exactly those things that are in the file.
// Things that get calculated later, in particular tangents, get added later.
- (GLLVertexAttribAccessorSet*)accessorsForFileData:(NSData *)baseData format:(GLLVertexFormat *)fileVertexFormat;

@end

@implementation GLLModelMesh

#pragma mark - Mesh loading

- (id)initAsPartOfModel:(GLLModel *)model;
{
    if (!(self = [super init])) return nil;
    
    _model = model;
    _elementComponentType = GLLVertexAttribComponentTypeUnsignedInt;
    _initiallyVisible = YES;
    
    return self;
}

- (id)initFromStream:(TRInDataStream *)stream partOfModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
{
    if (!(self = [super init])) return nil;
    
    GLLBeginTiming("Binary mesh");
    
    _model = model;
    _elementComponentType = GLLVertexAttribComponentTypeUnsignedInt;
    
    _name = [stream readPascalString];
    _countOfUVLayers = [stream readUint32];
    
    NSUInteger numTextures = [stream readUint32];
    NSMutableDictionary<NSString *, GLLTextureAssignment *> *textures = [[NSMutableDictionary alloc] initWithCapacity:numTextures];
    
    GLLMeshParams *meshParams = [_model.parameters paramsForMesh:_name];
    NSArray<NSString *> *textureIdentifiers = meshParams.shader.textureUniformNames;
    for (NSUInteger i = 0; i < numTextures; i++)
    {
        NSString *textureName = [stream readPascalString];
        [stream readUint32]; // UV layer. Ignored; the shader always has the UV layer for the texture hardcoded.
        NSString *finalPathComponent = [[textureName componentsSeparatedByString:@"\\"] lastObject];
        if (!finalPathComponent) return nil;
        
        NSString *textureIdentifier = (textureIdentifiers && i < textureIdentifiers.count) ? textureIdentifiers[i] : nil;
        if (textureIdentifier) {
            NSURL *textureUrl = [NSURL URLWithString:[finalPathComponent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]] relativeToURL:model.baseURL];
            textures[textureIdentifier] = [[GLLTextureAssignment alloc] initWithUrl:textureUrl];
        }
    }
    _textures = [textures copy];
    
    if (![stream isValid])
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off during the descriptions of a mesh. Maybe it is damaged?", @"Premature end of file error") }];
        return nil;
    }
    
    _countOfVertices = [stream readUint32];
    GLLVertexFormat *fileVertexFormat = self.fileVertexFormat;
    NSData *vertexData = [stream dataWithLength:_countOfVertices * fileVertexFormat.stride];
    if (!vertexData)
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The vertex data for a mesh could not be loaded.", @"Premature end of file error") }];
        return nil;
    }
    
    _countOfElements = 3 * [stream readUint32]; // File saves number of triangles
    _elementData = [stream dataWithLength:_countOfElements * sizeof(uint32_t)];
    
    if (![stream isValid])
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off inside a mesh's vertex data", @"Premature end of file error") }];
        return nil;
    }
    
    // Prepare the vertex data
    GLLVertexAttribAccessorSet* fileAccessors = [self accessorsForFileData:vertexData format:fileVertexFormat];
    
    if (![self validateVertexData:fileAccessors indexData:_elementData error:error])
        return nil;
    
    if (self.hasTangentsInFile) {
        _vertexDataAccessors = fileAccessors;
    } else {
        GLLVertexAttribAccessorSet* tangents = [self calculateTangents:fileAccessors];
        
        _vertexDataAccessors = [fileAccessors setByCombiningWith:tangents];
    }
    _vertexFormat = [_vertexDataAccessors vertexFormatWithVertexCount:_countOfVertices hasIndices:YES];
    
    [self finishLoading];
    
    GLLEndTiming("Binary mesh");
    
    return self;
}

- (id)initFromScanner:(GLLASCIIScanner *)scanner partOfModel:(GLLModel *)model error:(NSError *__autoreleasing *)error;
{
    if (!(self = [super init])) return nil;
    
    _model = model;
    _elementComponentType = GLLVertexAttribComponentTypeUnsignedInt;
    
    _name = [scanner readPascalString];
    _countOfUVLayers = [scanner readUint32];
    
    NSUInteger numTextures = [scanner readUint32];
    NSMutableDictionary<NSString *, GLLTextureAssignment *> *textures = [[NSMutableDictionary alloc] initWithCapacity:numTextures];
    
    GLLMeshParams *meshParams = [_model.parameters paramsForMesh:_name];
    NSArray<NSString *> *textureIdentifiers = meshParams.shader.textureUniformNames;
    for (NSUInteger i = 0; i < numTextures; i++)
    {
        NSString *textureName = [scanner readPascalString];
        [scanner readUint32]; // UV layer. Ignored; the shader always has the UV layer for the texture hardcoded.
        NSString *finalPathComponent = [[textureName componentsSeparatedByString:@"\\"] lastObject];
        if (!finalPathComponent) return nil;
        
        NSString *textureIdentifier = (textureIdentifiers && i < textureIdentifiers.count) ? textureIdentifiers[i] : nil;
        if (textureIdentifier) {
            NSURL *textureUrl = [NSURL URLWithString:[finalPathComponent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]] relativeToURL:model.baseURL];
            textures[textureIdentifier] = [[GLLTextureAssignment alloc] initWithUrl:textureUrl];
        }
    }
    _textures = [textures copy];
    
    _countOfVertices = [scanner readUint32];
    
    // Create vertex format
    GLLVertexFormat *fileVertexFormat = self.fileVertexFormat;
    NSMutableData *vertexData = [[NSMutableData alloc] initWithCapacity:_countOfVertices * fileVertexFormat.stride];
    for (NSUInteger i = 0; i < self.countOfVertices; i++)
    {
        // Vertices + normals
        for (NSUInteger j = 0; j < 6; j++)
        {
            float value = [scanner readFloat32];
            [vertexData appendBytes:&value length:sizeof(value)];
        }
        
        // Color
        for (NSUInteger j = 0; j < 4; j++)
        {
            uint8_t value = [scanner readUint8];
            [vertexData appendBytes:&value length:sizeof(value)];
        }
        // Tex coords
        for (NSUInteger j = 0; j < 2*_countOfUVLayers; j++)
        {
            float value = [scanner readFloat32];
            [vertexData appendBytes:&value length:sizeof(value)];
        }
        
        // Leave space for tangents
        for (NSUInteger j = 0; j < 4*_countOfUVLayers; j++)
        {
            float zero = 0.0f;
            [vertexData appendBytes:&zero length:sizeof(zero)];
        }
        
        if (self.hasBoneWeights)
        {
            // Bone indices
            NSUInteger boneIndexCount = 0;
            for (; boneIndexCount < 4; boneIndexCount++) {
                uint16_t value = [scanner readUint16];
                [vertexData appendBytes:&value length:sizeof(value)];
                
                // Some .mesh.ascii files have fewer bones and weights
                if ([scanner hasNewline]) {
                    boneIndexCount += 1;
                    break;
                }
            }
            for (; boneIndexCount < 4; boneIndexCount++) {
                uint16_t value = 0;
                [vertexData appendBytes:&value length:sizeof(value)];
            }
            
            // Bone weights
            float boneWeights[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
            for (NSUInteger boneWeightCount = 0; boneWeightCount < 4; boneWeightCount++) {
                boneWeights[boneWeightCount] = [scanner readFloat32];
                
                // Some .mesh.ascii files have fewer bones and weights
                if ([scanner hasNewline]) {
                    break;
                }
            }
            
            float sum = 0;
            for (int i = 0; i < 4; i++) {
                sum += boneWeights[i];
            }
            if (sum == 0.0) {
                boneWeights[0] = 1.0f;
                boneWeights[1] = 0.0f;
                boneWeights[2] = 0.0f;
                boneWeights[3] = 0.0f;
            } else if (sum != 1.0) {
                boneWeights[0] /= sum;
                boneWeights[1] /= sum;
                boneWeights[2] /= sum;
                boneWeights[3] /= sum;
            }
            
            [vertexData appendBytes:boneWeights length:sizeof(boneWeights)];
        }
    }
    
    _countOfElements = 3 * [scanner readUint32]; // File saves number of triangles
    NSMutableData *elementData = [[NSMutableData alloc] initWithCapacity:_countOfElements * sizeof(uint32_t)];
    for (NSUInteger i = 0; i < self.countOfElements; i++)
    {
        uint32_t element = [scanner readUint32];
        [elementData appendBytes:&element length:sizeof(element)];
    }
    _elementData = [elementData copy];
    
    // Prepare the vertex data
    GLLVertexAttribAccessorSet* fileAccessors = [self accessorsForFileData:vertexData format:fileVertexFormat];
    GLLVertexAttribAccessorSet* tangents = [self calculateTangents:fileAccessors];
    
    _vertexDataAccessors = [fileAccessors setByCombiningWith:tangents];
    _vertexFormat = [_vertexDataAccessors vertexFormatWithVertexCount:_countOfVertices hasIndices:YES];
    
    if (![self validateVertexData:_vertexDataAccessors indexData:_elementData error:error]) return nil;
    
    if (![scanner isValid])
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off in the middle of the meshes section. Maybe it is damaged?", @"Premature end of file error") }];
        return nil;
    }
    
    [self finishLoading];
    
    return self;
}

#pragma mark - Describe mesh data

- (GLLVertexFormat *)fileVertexFormat {
    NSMutableArray<GLLVertexAttrib *> *attributes = [NSMutableArray array];
    [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribPosition layer:0 size:GLLVertexAttribSizeVec3 componentType:GLLVertexAttribComponentTypeFloat]];
    [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribNormal layer:0 size:GLLVertexAttribSizeVec3 componentType:GLLVertexAttribComponentTypeFloat]];
    if (self.colorsAreFloats) {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribColor layer:0 size:GLLVertexAttribSizeVec4 componentType:GLLVertexAttribComponentTypeFloat]];
    } else {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribColor layer:0 size:GLLVertexAttribSizeVec4 componentType:GLLVertexAttribComponentTypeUnsignedByte]];
    }
    for (NSUInteger i = 0; i < self.countOfUVLayers; i++) {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribTexCoord0 layer:i size:GLLVertexAttribSizeVec2 componentType:GLLVertexAttribComponentTypeFloat]];
    }
    if (self.hasTangentsInFile) {
        for (NSUInteger i = 0; i < self.countOfUVLayers; i++) {
            [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribTangent0 layer:i size:GLLVertexAttribSizeVec4 componentType:GLLVertexAttribComponentTypeFloat]];
        }
    }
    if (self.hasBoneWeights) {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribBoneIndices layer:0 size:GLLVertexAttribSizeVec4 componentType:GLLVertexAttribComponentTypeUnsignedShort]];
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribBoneWeights layer:0 size:GLLVertexAttribSizeVec4 componentType:GLLVertexAttribComponentTypeFloat]];
    }

    return [[GLLVertexFormat alloc] initWithAttributes:attributes countOfVertices:0 hasIndices:YES];
}

- (GLLVertexAttribAccessorSet*)accessorsForFileData:(NSData *)baseData format:(GLLVertexFormat *)fileVertexFormat; {
    NSUInteger stride = fileVertexFormat.stride;
    
    NSUInteger offset = 0;
    NSMutableArray<GLLVertexAttribAccessor *>* accessors = [[NSMutableArray alloc] init];
    for (GLLVertexAttrib *attribute in fileVertexFormat.attributes) {
        [accessors addObject:[[GLLVertexAttribAccessor alloc] initWithAttribute:attribute dataBuffer:baseData offset:offset stride:stride]];
        offset += attribute.sizeInBytes;
    }
    
    return [[GLLVertexAttribAccessorSet alloc] initWithAccessors:accessors];
}

#pragma mark - Properties

- (BOOL)hasBoneWeights
{
    return self.model.hasBones;
}
- (NSURL *)baseURL
{
    return self.model.baseURL;
}

- (NSUInteger)meshIndex
{
    return [self.model.meshes indexOfObject:self];
}

- (BOOL)hasTangentsInFile
{
    // For subclasses to override
    return YES;
}

- (BOOL)colorsAreFloats
{
    // For subclasses to override
    return NO;
}

- (NSUInteger)countOfUsedElements {
    if (self.elementData == nil) {
        return self.countOfVertices;
    }
    return self.countOfElements;
}

#pragma mark - Splitting

- (GLLModelMesh *)partialMeshFromSplitter:(GLLMeshSplitter *)splitter;
{
    NSMutableData *newElements = [[NSMutableData alloc] init];
    
    GLLVertexAttribAccessor *positionData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribPosition];
    
    for (NSUInteger index = 0; index < self.countOfUsedElements; index += 3)
    {
        NSUInteger elements[3] = {
            [self elementAt:index + 0],
            [self elementAt:index + 1],
            [self elementAt:index + 2],
        };
        const float *position[3] = {
            [positionData elementAt:elements[0]],
            [positionData elementAt:elements[1]],
            [positionData elementAt:elements[2]],
        };
        
        // Find out if one corner is completely in the box. If yes, then this triangle becomes part of the split mesh.
        BOOL anyCornerInsideBox = NO;
        for (int corner = 0; corner < 3; corner++)
        {
            BOOL allCoordsInsideBox = YES;
            for (int coord = 0; coord < 3; coord++)
                allCoordsInsideBox = allCoordsInsideBox && position[corner][coord] >= splitter.min[coord].floatValue && position[corner][coord] <= splitter.max[coord].floatValue;
            if (allCoordsInsideBox)
                anyCornerInsideBox = YES;
        }
        
        // All outside - not part of the split mesh.
        if (!anyCornerInsideBox) continue;
        
        for (int corner = 0; corner < 3; corner++)
        {
            // Add this index to the new elements
            uint32_t index = (uint32_t) elements[corner];
            [newElements appendBytes:&index length:sizeof(index)];
        }
    }
    
    GLLModelMesh *result = [[GLLModelMesh alloc] init];
    result->_vertexFormat = _vertexFormat;
    result->_vertexDataAccessors = _vertexDataAccessors;
    result->_countOfVertices = _countOfVertices;
    result->_elementData = [newElements copy];
    result->_elementComponentType = GLLVertexAttribComponentTypeUnsignedInt;
    result->_countOfElements = newElements.length / sizeof(uint32_t);
    
    result->_countOfUVLayers = self.countOfUVLayers;
    result->_model = self.model;
    result->_name = [splitter.splitPartName copy];
    result->_textures = [self.textures copy];
    [result finishLoading]; // Result may have different mesh group or shader. In fact, for the one and only object class where this entire feature is needed, this is guaranteed.
    
    return result;
}

- (GLLCullFaceMode)cullFaceMode
{
    return GLLCullCounterClockWise;
}

#pragma mark - Export

- (NSString *)writeASCIIWithName:(NSString *)name texture:(NSArray *)textures;
{
    NSParameterAssert(name);
    NSParameterAssert(textures);
    
    GLLVertexAttribAccessor *positionAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribPosition];
    GLLVertexAttribAccessor *normalAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribPosition];
    GLLVertexAttribAccessor *colorAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribColor layer:0];
    GLLVertexAttribAccessor *boneIndexAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribBoneIndices];
    GLLVertexAttribAccessor *boneWeightAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribBoneWeights];

    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"%@\n", name];
    [result appendFormat:@"%lu\n", self.countOfUVLayers];
    [result appendFormat:@"%lu\n", textures.count];
    for (NSURL *texture in textures)
        [result appendFormat:@"%@\n0\n", texture.lastPathComponent];
    
    [result appendFormat:@"%lu\n", self.countOfVertices];
    for (NSUInteger i = 0; i < self.countOfVertices; i++)
    {
        const float *position = [positionAccessor elementAt:i];
        [result appendFormat:@"%f %f %f ", position[0], position[1], position[2]];
        const float *normal = [normalAccessor elementAt:i];
        [result appendFormat:@"%f %f %f ", normal[0], normal[1], normal[2]];
        const uint8_t *colors = [colorAccessor elementAt:i];
        [result appendFormat:@"%u %u %u %u ", colors[0], colors[1], colors[2], colors[3]];
        for (NSUInteger uvlayer = 0; uvlayer < self.countOfUVLayers; uvlayer++)
        {
            GLLVertexAttribAccessor *texCoordAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribTexCoord0 layer:uvlayer];

            const float *texCoords = [texCoordAccessor elementAt:i];
            [result appendFormat:@"%f %f ", texCoords[0], texCoords[1]];
        }
        if (self.hasBoneWeights)
        {
            const uint16_t *boneIndices = [boneIndexAccessor elementAt:i];
            [result appendFormat:@"%u %u %u %u ", boneIndices[0], boneIndices[1], boneIndices[2], boneIndices[3]];
            
            const float *boneWeights = [boneWeightAccessor elementAt:i];
            [result appendFormat:@"%f %f %f %f ", boneWeights[0], boneWeights[1], boneWeights[2], boneWeights[3]];
        }
        [result appendString:@"\n"];
    }
    
    [result appendFormat:@"%lu\n", self.countOfUsedElements / 3];
    for (NSUInteger i = 0; i < self.countOfUsedElements; i++)
        [result appendFormat:@"%lu ", [self elementAt:i]];
    [result appendString:@"\n"];
    
    return [result copy];
    return nil;
}

- (NSData *)writeBinaryWithName:(NSString *)name texture:(NSArray *)textures;
{
    NSParameterAssert(name);
    NSParameterAssert(textures);
    
    TROutDataStream *stream = [[TROutDataStream alloc] init];
    [stream appendPascalString:name];
    [stream appendUint32:(uint32_t) self.countOfUVLayers];
    [stream appendUint32:(uint32_t) textures.count];
    for (NSURL *texture in textures)
    {
        [stream appendPascalString:texture.lastPathComponent];
        [stream appendUint32:0];
    }
    [stream appendUint32:(uint32_t) self.countOfVertices];
    if (self.hasTangentsInFile) {
        [stream appendData:self.vertexDataAccessors.accessors.firstObject.dataBuffer];
    } else {
        // Long way round: Combine all the elements, no matter where they're from
        GLLVertexAttribAccessor *positionData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribPosition];
        GLLVertexAttribAccessor *normalData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribNormal];
        GLLVertexAttribAccessor *colorData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribColor];
        GLLVertexAttribAccessor *boneIndexData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribBoneIndices];
        GLLVertexAttribAccessor *boneWeightData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribBoneWeights];

        for (NSUInteger i = 0; i < self.countOfVertices; i++) {
            [stream appendData:[positionData elementDataAt:i]];
            [stream appendData:[normalData elementDataAt:i]];
            [stream appendData:[colorData elementDataAt:i]];
            for (NSUInteger layer = 0; layer < self.countOfUVLayers; layer++) {
                GLLVertexAttribAccessor *texCoordData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribTexCoord0 layer:layer];
                [stream appendData:[texCoordData elementDataAt:i]];
            }
            for (NSUInteger layer = 0; layer < self.countOfUVLayers; layer++) {
                GLLVertexAttribAccessor *tangentData = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribTangent0 layer:layer];
                [stream appendData:[tangentData elementDataAt:i]];
            }
            if (boneIndexData && boneWeightData) {
                [stream appendData:[boneIndexData elementDataAt:i]];
                [stream appendData:[boneWeightData elementDataAt:i]];
            }
        }
    }
    [stream appendUint32:(uint32_t) self.countOfUsedElements / 3UL];
    if (self.elementData && (self.elementComponentType == GLLVertexAttribComponentTypeInt || self.elementComponentType == GLLVertexAttribComponentTypeUnsignedInt)) {
        [stream appendData:self.elementData];
    } else {
        for (NSUInteger i = 0; i < self.countOfUsedElements; i++) {
            [stream appendUint32:(uint32_t) [self elementAt:i]];
        }
    }
    
    return stream.data;
}

#pragma mark - Postprocessing

- (GLLVertexAttribAccessorSet*)calculateTangents:(GLLVertexAttribAccessorSet *)fileVertexData;
{
    GLLVertexAttribAccessor *positionData = [fileVertexData accessorForSemantic:GLLVertexAttribPosition];
    GLLVertexAttribAccessor *normalData = [fileVertexData accessorForSemantic:GLLVertexAttribNormal];

    NSMutableArray<GLLVertexAttribAccessor *> *result = [[NSMutableArray alloc] init];
        
    for (NSUInteger layer = 0; layer < self.countOfUVLayers; layer++)
    {
        GLLVertexAttribAccessor *texCoordData = [fileVertexData accessorForSemantic:GLLVertexAttribTexCoord0 layer:layer];
        NSAssert(texCoordData, @"Have no tex coord data for layer %lu even though we have %lu layers", layer, self.countOfUVLayers);
        
        float *tangents = calloc(sizeof(float[4]), self.countOfVertices);
        
        float tangentsU[3*self.countOfVertices];
        float tangentsV[3*self.countOfVertices];
        bzero(tangentsU, sizeof(tangentsU));
        bzero(tangentsV, sizeof(tangentsV));
        
        // First pass: Sum up the tangents for each vector. We can assume that at the start of this method, the tangent for every vertex is (0, 0, 0, 0)^t.
        for (NSUInteger index = 0; index < self.countOfUsedElements; index += 3)
        {
            NSUInteger elements[3] = {
                [self elementAt:index + 0],
                [self elementAt:index + 1],
                [self elementAt:index + 2],
            };
            const float *positions[3] = {
                [positionData elementAt:elements[0]],
                [positionData elementAt:elements[1]],
                [positionData elementAt:elements[2]],
            };
            const float *texCoords[3] = {
                [texCoordData elementAt:elements[0]],
                [texCoordData elementAt:elements[1]],
                [texCoordData elementAt:elements[2]],
            };
            
            // Calculate tangents
            float q1[3] = { positions[1][0] - positions[0][0], positions[1][1] - positions[0][1], positions[1][2] - positions[0][2] };
            float q2[3] = { positions[1][0] - positions[0][0], positions[1][1] - positions[0][1], positions[1][2] - positions[0][2] };
            
            float s1 = texCoords[1][0] - texCoords[0][0];
            float t1 = texCoords[1][1] - texCoords[0][1];
            float s2 = texCoords[2][0] - texCoords[0][0];
            float t2 = texCoords[2][1] - texCoords[0][1];
            float d = s1 * t2 - s2 * t1;
            if (d == 0) continue;
            
            float tangentU[3] = {
                (t2 * q1[0] - t1 * q2[0]) / d,
                (t2 * q1[1] - t1 * q2[1]) / d,
                (t2 * q1[2] - t1 * q2[2]) / d,
            };
            vec_normalize(tangentU);
            float tangentV[3] = {
                (s2 * q2[0] - s1 * q1[0]) / d,
                (s2 * q2[1] - s1 * q1[1]) / d,
                (s2 * q2[2] - s1 * q1[2]) / d,
            };
            vec_normalize(tangentV);
            
            // Add them to the per-layer tangents
            for (int vertex = 0; vertex < 3; vertex++)
            {
                vec_addTo(&tangentsU[elements[index + vertex]*3], tangentU);
                vec_addTo(&tangentsV[elements[index + vertex]*3], tangentV);
            }
        }
        
        for (NSUInteger vertex = 0; vertex < self.countOfVertices; vertex++)
        {
            float *tangentU = &tangentsU[vertex*3];
            vec_normalize(tangentU);
            float *tangentV = &tangentsV[vertex*3];
            vec_normalize(tangentV);
            
            const float *normal = [normalData elementAt:vertex];
            
            float normalDotTangentU = vec_dot(normal, &tangentsU[vertex*3]);
            float tangent[3] = {
                tangentsU[vertex*3 + 0] - normal[0] * normalDotTangentU,
                tangentsU[vertex*3 + 1] - normal[1] * normalDotTangentU,
                tangentsU[vertex*3 + 2] - normal[2] * normalDotTangentU,
            };
            vec_normalize(tangent);
            float w = tangentsV[vertex*3 + 0] * (normal[1] * tangentU[2] - normal[2] * tangentU[1]) +
            tangentsV[vertex*3 + 1] * (normal[2] * tangentU[0] - normal[0] * tangentU[2]) +
            tangentsV[vertex*3 + 2] * (normal[0] * tangentU[1] - normal[1] * tangentU[0]);
            
            float *target = &tangents[vertex*4];
            target[0] = tangent[0];
            target[1] = tangent[1];
            target[2] = tangent[2];
            target[3] = w > 0.0f ? 1.0f : -1.0f;
        }
        
        NSData *tangentsData = [NSData dataWithBytesNoCopy:tangents length:sizeof(float[4]) * self.countOfVertices freeWhenDone:YES];
        GLLVertexAttrib* attribute = [[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribTangent0 layer:layer size:GLLVertexAttribSizeVec4 componentType:GLLVertexAttribComponentTypeFloat];
        [result addObject:[[GLLVertexAttribAccessor alloc] initWithAttribute:attribute dataBuffer:tangentsData offset:0 stride:attribute.sizeInBytes]];
    }
    return [[GLLVertexAttribAccessorSet alloc] initWithAccessors:result];
}

- (BOOL)validateVertexData:(GLLVertexAttribAccessorSet *)fileVertexData indexData:(NSData *)indexData error:(NSError *__autoreleasing*)error;
{
    GLLVertexAttribAccessor *boneIndexData = [fileVertexData accessorForSemantic:GLLVertexAttribBoneIndices];
    
    // Check bone indices
    if (boneIndexData)
    {
        for (NSUInteger i = 0; i < self.countOfVertices; i++)
        {
            const uint16_t *indices = [boneIndexData elementAt:i];
            
            for (NSUInteger j = 0; j < 4; j++)
            {
                if (indices[j] >= self.model.bones.count)
                {
                    if (error)
                        *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_IndexOutOfRange userInfo:@{
                                                                                                                                          NSLocalizedDescriptionKey : NSLocalizedString(@"The file references bones that do not exist.", @"Bone index out of range error"),
                                                                                                                                          NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"An index in the bone references is out of range", @"Bone index out of range error")}];
                    
                    return NO;
                }
            }
        }
    }
    
    // Check element indices
    const uint32_t *indices = indexData.bytes;
    for (NSUInteger i = 0; i < self.countOfElements; i++)
    {
        if (indices[i] >= self.countOfVertices)
        {
            if (error)
                *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_IndexOutOfRange userInfo:@{
                                                                                                                                  NSLocalizedDescriptionKey : NSLocalizedString(@"A mesh references vertices that do not exist.", @"Vertex index out of range error"),
                                                                                                                                  NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"An index in the graphics data is out of range", @"Vertex index out of range error") }];
            
            return NO;
        }
    }
    
    return YES;
}

- (void)finishLoading;
{
    GLLMeshParams *meshParams = [_model.parameters paramsForMesh:_name];
    
    _shader = meshParams.shader;
    _usesAlphaBlending = meshParams.transparent;
    _displayName = meshParams.displayName;
    _initiallyVisible = meshParams.visible;
    _optionalPartNames = meshParams.optionalPartNames;
    _renderParameterValues = meshParams.renderParameters;
    
    if (!_shader)
        NSLog(@"No shader for object %@", self.name);
}

- (NSUInteger)elementAt:(NSUInteger)index {
    if (!_elementData) {
        return index; // Use direct values
    }
    const void *bytes = _elementData.bytes;
    switch (_elementComponentType) {
        case GLLVertexAttribComponentTypeByte:
            return (NSUInteger) ((const int8_t *) bytes)[index];
        case GLLVertexAttribComponentTypeUnsignedByte:
            return (NSUInteger) ((const uint8_t *) bytes)[index];
        case GLLVertexAttribComponentTypeShort:
            return (NSUInteger) ((const int16_t *) bytes)[index];
        case GLLVertexAttribComponentTypeUnsignedShort:
            return (NSUInteger) ((const uint16_t *) bytes)[index];
        case GLLVertexAttribComponentTypeInt:
            return (NSUInteger) ((const int32_t *) bytes)[index];
        case GLLVertexAttribComponentTypeUnsignedInt:
            return (NSUInteger) ((const uint32_t *) bytes)[index];
        default:
            NSAssert(false, @"Wrong element component type");
            return 0; // to silence compiler warning
    }
}

@end
