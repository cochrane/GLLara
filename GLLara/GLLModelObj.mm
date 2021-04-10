//
//  GLLModelObj.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelObj.h"

#import "GLLModelBone.h"
#import "GLLModelMeshObj.h"
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
    self.bones = @[ [[GLLModelBone alloc] initWithModel:self] ];
    
    // 2. Set up meshes. We use one mesh per material group.
    NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:file->getMaterialRanges().size()];
    NSUInteger meshNumber = 1;
    GLLBeginTiming("OBJ file postprocess");
    for (auto &range : file->getMaterialRanges())
    {
        GLLModelMeshObj *mesh = [[GLLModelMeshObj alloc] initWithObjFile:file mtlFiles:materialFiles range:range inModel:self error:error];
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
