//
//  GLLModelMesh.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh.h"

#import "GLLASCIIScanner.h"
#import "GLLMeshSplitter.h"
#import "GLLModel.h"
#import "GLLModelParams.h"
#import "GLLTiming.h"
#import "GLLVertexFormat.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

float vec_dot(float *a, float *b)
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
void vec_addTo(float *a, float *b)
{
    a[0] += b[0];
    a[1] += b[1];
    a[2] += b[2];
}

@implementation GLLModelMesh

#pragma mark - Mesh loading

- (id)initAsPartOfModel:(GLLModel *)model;
{
    if (!(self = [super init])) return nil;
    
    _model = model;
    
    return self;
}

- (id)initFromStream:(TRInDataStream *)stream partOfModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
{
    if (!(self = [super init])) return nil;
    
    GLLBeginTiming("Binary mesh");
    
    _model = model;
    
    _name = [stream readPascalString];
    _countOfUVLayers = [stream readUint32];
    
    NSUInteger numTextures = [stream readUint32];
    NSMutableArray<NSURL *> *textures = [[NSMutableArray alloc] initWithCapacity:numTextures];
    for (NSUInteger i = 0; i < numTextures; i++)
    {
        NSString *textureName = [stream readPascalString];
        
        NSString *finalPathComponent = [[textureName componentsSeparatedByString:@"\\"] lastObject];
        if (!finalPathComponent)
        {
            return nil;
        }
        [textures addObject:[NSURL URLWithString:[finalPathComponent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]] relativeToURL:model.baseURL]];
        
        
        [stream readUint32]; // UV layer. Ignored; the shader always has the UV layer for the texture hardcoded.
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
    NSData *rawVertexData = [stream dataWithLength:_countOfVertices * self.vertexFormat.stride];
    if (!rawVertexData)
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The vertex data for a mesh could not be loaded.", @"Premature end of file error") }];
        return nil;
    }
    _vertexData = rawVertexData;
    
    _countOfElements = 3 * [stream readUint32]; // File saves number of triangles
    _elementData = [stream dataWithLength:_countOfElements * sizeof(uint32_t)];
    
    if (![self validateVertexData:rawVertexData indexData:_elementData error:error])
        return nil;
    
    if (![stream isValid])
    {
        if (error)
            *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
                                                                                                                                 NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
                                                                                                                                 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file breaks off inside a mesh's vertex data", @"Premature end of file error") }];
        return nil;
    }
    
    [self finishLoading];
    
    GLLEndTiming("Binary mesh");
    
    return self;
}

- (id)initFromScanner:(GLLASCIIScanner *)scanner partOfModel:(GLLModel *)model error:(NSError *__autoreleasing *)error;
{
    if (!(self = [super init])) return nil;
    
    _model = model;
    
    _name = [scanner readPascalString];
    _countOfUVLayers = [scanner readUint32];
    
    NSUInteger numTextures = [scanner readUint32];
    NSMutableArray *textures = [[NSMutableArray alloc] initWithCapacity:numTextures];
    for (NSUInteger i = 0; i < numTextures; i++)
    {
        NSString *textureName = [scanner readPascalString];
        [scanner readUint32]; // UV layer. Ignored; the shader always has the UV layer for the texture hardcoded.
        NSString *finalPathComponent = [[textureName componentsSeparatedByString:@"\\"] lastObject];
        if (!finalPathComponent) return nil;
        [textures addObject:[NSURL URLWithString:[finalPathComponent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]] relativeToURL:model.baseURL]];
    }
    _textures = [textures copy];
    
    _countOfVertices = [scanner readUint32];
    NSMutableData *rawVertexData = [[NSMutableData alloc] initWithCapacity:_countOfVertices * self.vertexFormat.stride];
    for (NSUInteger i = 0; i < self.countOfVertices; i++)
    {
        // Vertices + normals
        for (NSUInteger j = 0; j < 6; j++)
        {
            float value = [scanner readFloat32];
            [rawVertexData appendBytes:&value length:sizeof(value)];
        }
        
        // Color
        for (NSUInteger j = 0; j < 4; j++)
        {
            uint8_t value = [scanner readUint8];
            [rawVertexData appendBytes:&value length:sizeof(value)];
        }
        // Tex coords
        for (NSUInteger j = 0; j < 2*_countOfUVLayers; j++)
        {
            float value = [scanner readFloat32];
            [rawVertexData appendBytes:&value length:sizeof(value)];
        }
        
        // Leave space for tangents
        for (NSUInteger j = 0; j < 4*_countOfUVLayers; j++)
        {
            float zero = 0.0f;
            [rawVertexData appendBytes:&zero length:sizeof(zero)];
        }
        
        if (self.hasBoneWeights)
        {
            // Bone indices
            NSUInteger boneIndexCount = 0;
            for (; boneIndexCount < 4; boneIndexCount++) {
                uint16_t value = [scanner readUint16];
                [rawVertexData appendBytes:&value length:sizeof(value)];
                
                // Some .mesh.ascii files have fewer bones and weights
                if ([scanner hasNewline]) {
                    boneIndexCount += 1;
                    break;
                }
            }
            for (; boneIndexCount < 4; boneIndexCount++) {
                uint16_t value = 0;
                [rawVertexData appendBytes:&value length:sizeof(value)];
            }
            
            // Bone weights
            NSUInteger boneWeightCount = 0;
            for (; boneWeightCount < 4; boneWeightCount++) {
                float value = [scanner readFloat32];
                [rawVertexData appendBytes:&value length:sizeof(value)];
                
                // Some .mesh.ascii files have fewer bones and weights
                if ([scanner hasNewline]) {
                    boneWeightCount += 1;
                    break;
                }
            }
            for (; boneWeightCount < 4; boneWeightCount++) {
                float value = 0.0;
                [rawVertexData appendBytes:&value length:sizeof(value)];
            }
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
    
    
    if (![self validateVertexData:rawVertexData indexData:_elementData error:error]) return nil;
    [self calculateTangents:rawVertexData];
    _vertexData = [[self normalizeBoneWeightsInVertices:rawVertexData] copy];
    
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

- (GLLVertexFormat *)vertexFormat {
    if (!_vertexFormat) {
        _vertexFormat = [[GLLVertexFormat alloc] initWithBoneWeights:self.hasBoneWeights tangents:self.hasTangents colorsAsFloats:self.colorsAreFloats countOfUVLayers:self.countOfUVLayers countOfVertices:self.countOfVertices];
    }
    return _vertexFormat;
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

- (BOOL)hasTangents
{
    // For subclasses to override
    return YES;
}

- (BOOL)colorsAreFloats
{
    // For subclasses to override
    return NO;
}

#pragma mark - Splitting

- (GLLModelMesh *)partialMeshInBoxMin:(const float *)min max:(const float *)max name:(NSString *)name;
{
    NSMutableData *newVertices = [[NSMutableData alloc] init];
    NSMutableData *newElements = [[NSMutableData alloc] init];
    NSUInteger newVerticesCount = 0;
    NSMutableDictionary *oldToNewVertices = [[NSMutableDictionary alloc] init];
    
    GLLVertexFormat *vertexFormat = self.vertexFormat;
    const NSUInteger stride = vertexFormat.stride;
    const NSUInteger positionOffset = vertexFormat.offsetForPosition;
    const NSUInteger countOfFaces = self.countOfElements / 3;
    
    const void *oldBytes = self.vertexData.bytes;
    const uint32_t *oldElements = self.elementData.bytes;
    
    for (NSUInteger i = 0; i < countOfFaces; i++)
    {
        const uint32_t *indices = &oldElements[i*3];
        
        const float *position[3] = {
            &oldBytes[indices[0]*stride + positionOffset],
            &oldBytes[indices[1]*stride + positionOffset],
            &oldBytes[indices[2]*stride + positionOffset]
        };
        
        // Find out if one corner is completely in the box. If yes, then this triangle becomes part of the split mesh.
        BOOL anyCornerInsideBox = NO;
        for (int corner = 0; corner < 3; corner++)
        {
            BOOL allCoordsInsideBox = YES;
            for (int coord = 0; coord < 3; coord++)
                allCoordsInsideBox = allCoordsInsideBox && position[corner][coord] >= min[coord] && position[corner][coord] <= max[coord];
            if (allCoordsInsideBox)
                anyCornerInsideBox = YES;
        }
        
        // All outside - not part of the split mesh.
        if (!anyCornerInsideBox) continue;
        
        for (int corner = 0; corner < 3; corner++)
        {
            // If this vertex is already in the new mesh, then just add the index. Otherwise, add the vertex itself to the vertices, too.
            NSNumber *newIndex = oldToNewVertices[@(indices[corner])];
            if (!newIndex)
            {
                [newVertices appendBytes:&oldBytes[indices[corner] * stride] length:stride];
                
                newIndex = @(newVerticesCount);
                oldToNewVertices[@(indices[corner])] = newIndex;
                newVerticesCount += 1;
            }
            uint32_t index = newIndex.unsignedIntValue;
            [newElements appendBytes:&index length:sizeof(index)];
        }
    }
    
    GLLModelMesh *result = [[GLLModelMesh alloc] init];
    result->_vertexData = [newVertices copy];
    result->_elementData = [newElements copy];
    
    result->_countOfUVLayers = self.countOfUVLayers;
    result->_model = self.model;
    result->_name = [name copy];
    result->_textures = [self.textures copy];
    [result finishLoading]; // Result may have different mesh group or shader. In fact, for the one and only object class where this entire feature is needed, this is guaranteed.
    
    return result;
}
- (GLLModelMesh *)partialMeshFromSplitter:(GLLMeshSplitter *)splitter;
{
    return [self partialMeshInBoxMin:splitter.min max:splitter.max name:splitter.splitPartName];
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
    
    GLLVertexFormat *vertexFormat = self.vertexFormat;
    
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"%@\n", name];
    [result appendFormat:@"%lu\n", self.countOfUVLayers];
    [result appendFormat:@"%lu\n", textures.count];
    for (NSURL *texture in textures)
        [result appendFormat:@"%@\n0\n", texture.lastPathComponent];
    
    [result appendFormat:@"%lu\n", self.countOfVertices];
    const void *vertexBytes = self.vertexData.bytes;
    for (NSUInteger i = 0; i < self.countOfVertices; i++)
    {
        const float *position = (const float *) (vertexBytes + i*vertexFormat.stride + vertexFormat.offsetForPosition);
        [result appendFormat:@"%f %f %f ", position[0], position[1], position[2]];
        const float *normal = (const float *) (vertexBytes + i*vertexFormat.stride + vertexFormat.offsetForNormal);
        [result appendFormat:@"%f %f %f ", normal[0], normal[1], normal[2]];
        const uint8_t *colors = (const uint8_t *) (vertexBytes + i*vertexFormat.stride + vertexFormat.offsetForColor);
        [result appendFormat:@"%u %u %u %u ", colors[0], colors[1], colors[2], colors[3]];
        for (NSUInteger uvlayer = 0; uvlayer < self.countOfUVLayers; uvlayer++)
        {
            const float *texCoords = (const float *) (vertexBytes + i*vertexFormat.stride + [vertexFormat offsetForTexCoordLayer:0]);
            [result appendFormat:@"%f %f ", texCoords[0], texCoords[1]];
        }
        if (self.hasBoneWeights)
        {
            const uint16_t *boneIndices = (const uint16_t *) (vertexBytes + i*vertexFormat.stride + vertexFormat.offsetForBoneIndices);
            [result appendFormat:@"%u %u %u %u ", boneIndices[0], boneIndices[1], boneIndices[2], boneIndices[3]];
            
            const float *boneWeights = (const float *) (vertexBytes + i*vertexFormat.stride + vertexFormat.offsetForBoneWeights);
            [result appendFormat:@"%f %f %f %f ", boneWeights[0], boneWeights[1], boneWeights[2], boneWeights[3]];
        }
        [result appendString:@"\n"];
    }
    
    [result appendFormat:@"%lu\n", self.countOfElements / 3];
    const uint32_t *elements = self.elementData.bytes;
    for (NSUInteger i = 0; i < self.countOfElements; i++)
        [result appendFormat:@"%u ", elements[i]];
    [result appendString:@"\n"];
    
    return [result copy];
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
    [stream appendData:self.vertexData];
    [stream appendUint32:(uint32_t) self.countOfElements / 3UL];
    [stream appendData:self.elementData];
    
    return stream.data;
}

#pragma mark - Postprocessing

- (void)calculateTangents:(NSMutableData *)vertexData;
{
    GLLVertexFormat *vertexFormat = self.vertexFormat;
    
    const NSUInteger stride = vertexFormat.stride;
    const NSUInteger positionOffset = vertexFormat.offsetForPosition;
    const NSUInteger normalOffset = vertexFormat.offsetForNormal;
    
    void *bytes = vertexData.mutableBytes;
    const uint32_t *elements = self.elementData.bytes;
    
    if (self.countOfVertices == 0)
        return;
    
    for (NSUInteger layer = 0; layer < self.countOfUVLayers; layer++)
    {
        const NSUInteger texCoordOffset = [vertexFormat offsetForTexCoordLayer:layer];
        
        float tangentsU[3*self.countOfVertices];
        float tangentsV[3*self.countOfVertices];
        bzero(tangentsU, sizeof(tangentsU));
        bzero(tangentsV, sizeof(tangentsV));
        
        // First pass: Sum up the tangents for each vector. We can assume that at the start of this method, the tangent for every vertex is (0, 0, 0, 0)^t.
        for (NSUInteger index = 0; index < self.countOfElements; index += 3)
        {
            float *positions[3] = {
                &bytes[elements[index + 0] * stride + positionOffset],
                &bytes[elements[index + 1] * stride + positionOffset],
                &bytes[elements[index + 2] * stride + positionOffset]
            };
            
            float *texCoords[3] = {
                &bytes[elements[index + 0] * stride + texCoordOffset],
                &bytes[elements[index + 1] * stride + texCoordOffset],
                &bytes[elements[index + 2] * stride + texCoordOffset]
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
        
        const NSUInteger tangentOffset = [vertexFormat offsetForTangentLayer:layer];
        for (NSUInteger vertex = 0; vertex < self.countOfVertices; vertex++)
        {
            float *tangentU = &tangentsU[vertex*3];
            vec_normalize(tangentU);
            float *tangentV = &tangentsV[vertex*3];
            vec_normalize(tangentV);
            
            float *normal = &bytes[vertex*stride + normalOffset];
            
            float normalDotTangentU = vec_dot(&bytes[vertex*stride + normalOffset], &tangentsU[vertex*3]);
            float tangent[3] = {
                tangentsU[vertex*3 + 0] - normal[0] * normalDotTangentU,
                tangentsU[vertex*3 + 1] - normal[1] * normalDotTangentU,
                tangentsU[vertex*3 + 2] - normal[2] * normalDotTangentU,
            };
            vec_normalize(tangent);
            float w = tangentsV[vertex*3 + 0] * (normal[1] * tangentU[2] - normal[2] * tangentU[1]) +
            tangentsV[vertex*3 + 1] * (normal[2] * tangentU[0] - normal[0] * tangentU[2]) +
            tangentsV[vertex*3 + 2] * (normal[0] * tangentU[1] - normal[1] * tangentU[0]);
            
            float *target = &bytes[vertex*stride + tangentOffset];
            target[0] = tangent[0];
            target[1] = tangent[1];
            target[2] = tangent[2];
            target[3] = w > 0.0f ? 1.0f : -1.0f;
        }
    }
}

- (BOOL)validateVertexData:(NSData *)vertices indexData:(NSData *)indexData error:(NSError *__autoreleasing*)error;
{
    GLLVertexFormat *vertexFormat = self.vertexFormat;
    
    // Check bone indices
    if (self.hasBoneWeights)
    {
        const void *vertexData = vertices.bytes;
        for (NSUInteger i = 0; i < self.countOfVertices; i++)
        {
            const uint16_t *indices = vertexData + i*vertexFormat.stride + vertexFormat.offsetForBoneIndices;
            
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

- (NSData *)normalizeBoneWeightsInVertices:(NSData *)vertexData;
{
    NSParameterAssert(vertexData);
    
    if (!self.hasBoneWeights)
        return vertexData; // No processing necessary
    
    NSMutableData *mutableVertices = [vertexData mutableCopy];
    void *bytes = mutableVertices.mutableBytes;
    const NSUInteger boneWeightOffset = self.vertexFormat.offsetForBoneWeights;
    const NSUInteger stride = self.vertexFormat.stride;
    
    for (NSUInteger i = 0; i < self.countOfVertices; i++)
    {
        float *weights = &bytes[boneWeightOffset + i*stride];
        
        // Normalize weights. If no weights, use first bone.
        float weightSum = 0.0f;
        for (int i = 0; i < 4; i++)
            weightSum += weights[i];
        
        if (weightSum == 0.0f)
            weights[0] = 1.0f;
        else if (weightSum != 1.0f)
        {
            for (int i = 0; i < 4; i++)
                weights[i] /= weightSum;
        }
    }
    
    return mutableVertices;
}

- (void)finishLoading;
{
    GLLMeshParams *meshParams = [_model.parameters paramsForMesh:_name];
    
    _shader = meshParams.shader;
    _usesAlphaBlending = meshParams.transparent;
    _displayName = meshParams.displayName;
    _initiallyVisible = meshParams.visible;
    _optionalPartNames = meshParams.optionalPartNames;
    
    if (!_shader)
        NSLog(@"No shader for object %@", self.name);
}

@end
