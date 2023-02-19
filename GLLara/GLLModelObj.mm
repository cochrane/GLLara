//
//  GLLModelObj.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelObj.h"

#import <AppKit/NSColor.h>

#import "GLLMtlFile.h"
#import "GLLObjFile.h"
#import "GLLTiming.h"

#import "GLLara-Swift.h"

@interface GLLModelObj ()
{
    GLLObjFile *file;
    std::vector<GLLMtlFile *> materialFiles;
}

@end

@implementation GLLModelObj

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing*)error;
{
    if (!(self = [super init])) return nil;
    
    self.baseURL = url;
    
    try {
        file = new GLLObjFile((__bridge CFURLRef) url);
        
        NSArray *materialLibraryURLs = (__bridge NSArray *) file->getMaterialLibaryURLs();
        
        for (NSURL *url in materialLibraryURLs)
            materialFiles.push_back(new GLLMtlFile((__bridge CFURLRef) url));
        
        if (materialLibraryURLs.count == 0) {
            try {
                NSURL *guessedURL = [url.URLByDeletingPathExtension URLByAppendingPathExtension:@"mtl"];
                materialFiles.push_back(new GLLMtlFile((__bridge CFURLRef) guessedURL));
            } catch (std::exception &e) {
                // That file doesn't exist. Too bad.
            }
        }
        
    } catch (std::exception &e) {
        if (error)
            *error = [NSError errorWithDomain:@"GLLModelObj" code:1 userInfo:@{
                                                                               NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error loading the file.", @"couldn't load obj file"),
                                                                               NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Underlying error: %s", @"C++ threw exception"), e.what()]
                                                                               }];
        return nil;
    }
    
    // 1. Set up bones. We only have the one.
    self.bones = @[ [[GLLModelBone alloc] init] ];
    
    // 2. Set up meshes. We use one mesh per material group.
    NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:file->getMaterialRanges().size()];
    NSUInteger meshNumber = 1;
    GLLBeginTiming("OBJ file postprocess");
    for (auto &range : file->getMaterialRanges())
    {
        // Procedure: Go through the indices in the range. For each index, load the vertex data from the file and put it in the vertex buffer here. Adjust the index, too.
        GLLBeginTiming("OBJ mesh vertex copy");
        std::unordered_map<unsigned, uint32_t> globalToLocalVertices;
        NSMutableData *vertices = [[NSMutableData alloc] initWithCapacity:sizeof(GLLObjFile::VertexData) * (range.end - range.start)];
        uint32_t *elementData = (uint32_t *) malloc(sizeof(uint32_t)*(range.end - range.start));
        
        for (unsigned i = range.start; i < range.end; i++)
        {
            unsigned globalIndex = file->getIndices().at(i);
            uint32_t index = 0;
            auto localIndexIter = globalToLocalVertices.find(globalIndex);
            if (localIndexIter == globalToLocalVertices.end())
            {
                // Add adjusted element
                index = (uint32_t) globalToLocalVertices.size();
                globalToLocalVertices[globalIndex] = index;
                elementData[i - range.start] = index;
                
                // Add vertex
                const GLLObjFile::VertexData &vertex = file->getVertexData().at(globalIndex);
                
                [vertices appendBytes:vertex.vert length:sizeof(vertex.vert)];
                [vertices appendBytes:vertex.norm length:sizeof(vertex.norm)];
                [vertices appendBytes:vertex.color length:sizeof(vertex.color)];
                float texCoordY = 1.0f - vertex.tex[1]; // Turn tex coords around (because I don't want to swap the whole image)
                [vertices appendBytes:vertex.tex length:sizeof(vertex.tex[0])];
                [vertices appendBytes:&texCoordY length:sizeof(vertex.tex[1])];
                
                // No bone weights or indices here; OBJs use special shaders that don't use them.
            }
            else
                elementData[i - range.start] = localIndexIter->second;
        }
        
        // Set up vertex attributes
        GLLVertexAttribAccessorSet *fileAccessors = [[GLLVertexAttribAccessorSet alloc] initWithAccessors:@[
        [[GLLVertexAttribAccessor alloc] initWithSemantic:GLLVertexAttribPosition layer:0 format: MTLVertexFormatFloat3 dataBuffer:vertices offset:offsetof(GLLObjFile::VertexData, vert) stride:sizeof(GLLObjFile::VertexData)],
        [[GLLVertexAttribAccessor alloc] initWithSemantic:GLLVertexAttribNormal layer:0 format: MTLVertexFormatFloat3 dataBuffer:vertices offset:offsetof(GLLObjFile::VertexData, norm) stride:sizeof(GLLObjFile::VertexData)],
        [[GLLVertexAttribAccessor alloc] initWithSemantic:GLLVertexAttribColor layer:0 format: MTLVertexFormatFloat4 dataBuffer:vertices offset:offsetof(GLLObjFile::VertexData, color) stride:sizeof(GLLObjFile::VertexData)],
        [[GLLVertexAttribAccessor alloc] initWithSemantic:GLLVertexAttribTexCoord0 layer:0 format: MTLVertexFormatFloat2 dataBuffer:vertices offset:offsetof(GLLObjFile::VertexData, tex) stride:sizeof(GLLObjFile::VertexData)]]];
        
        NSData *elementDataWrapped = [NSData dataWithBytesNoCopy:elementData length:sizeof(uint32_t) * (range.end - range.start) freeWhenDone:YES];

        // Setup material
        // Three options: Diffuse, DiffuseSpecular, DiffuseNormal, DiffuseSpecularNormal
        
        const GLLMtlFile::Material *material = NULL;
        for (auto iter = materialFiles.begin(); iter != materialFiles.end(); iter++)
        {
            if ((*iter)->hasMaterial(range.materialName))
            {
                material = (*iter)->getMaterial(range.materialName);
                break;
            }
        }
        NSMutableDictionary *textures = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *renderParameterValues = [[NSMutableDictionary alloc] initWithDictionary:
                                                      @{ @"ambientColor" : [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0],
                                                         @"diffuseColor" : [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0],
                                                         @"specularColor" : [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0],
                                                         @"specularExponent": @(1.0)
                                                      }];
        if (material) {
            if (material->diffuseTexture) {
                textures[@"diffuseTexture"] = [[GLLTextureAssignment alloc] initWithUrl:(__bridge NSURL *) material->diffuseTexture texCoordSet: 0];
            }
            if (material->specularTexture) {
                textures[@"specularTexture"] = [[GLLTextureAssignment alloc] initWithUrl:(__bridge NSURL *) material->specularTexture texCoordSet: 0];
            }
            if (material->normalTexture) {
                textures[@"bumpTexture"] = [[GLLTextureAssignment alloc] initWithUrl:(__bridge NSURL *) material->normalTexture texCoordSet: 0];
            }
            renderParameterValues[@"ambientColor"] = [NSColor colorWithCalibratedRed:material->ambient[0] green:material->ambient[1] blue:material->ambient[2] alpha:material->ambient[3]];
            renderParameterValues[@"diffuseColor"] = [NSColor colorWithCalibratedRed:material->diffuse[0] green:material->diffuse[1] blue:material->diffuse[2] alpha:material->diffuse[3]];
            renderParameterValues[@"diffuseColor"] = [NSColor colorWithCalibratedRed:material->specular[0] green:material->specular[1] blue:material->specular[2] alpha:material->specular[3]];
            renderParameterValues[@"specularExponent"] = @(material->shininess);
        }
        
        GLLModelMeshObj *mesh = [[GLLModelMeshObj alloc] initAsPartOfModel: self fileVertexAccessors:fileAccessors countOfVertices:NSInteger(globalToLocalVertices.size()) elementData:elementDataWrapped textures:textures renderParameterValues:renderParameterValues error:error];
        if (!mesh) return nil;
        mesh.name = [NSString stringWithFormat:NSLocalizedString(@"Mesh %lu", "Mesh name for obj format"), meshNumber++];
        mesh.displayName = mesh.name;
        [meshes addObject:mesh];
    }
    self.meshes = [meshes copy];
    GLLEndTiming("OBJ file postprocess");
    
    NSError *paramError = nil;
    self.parameters = [GLLModelParams parametersForName:@"objFileParameters" error:&paramError];
    NSAssert(self.parameters && !paramError, @"Should have params (are %@), no error (is %@)", self.parameters, paramError);
    
    return self;
}

@end
