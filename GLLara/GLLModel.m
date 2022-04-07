//
//  GLLModel.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModel.h"

#import "NSArray+Map.h"
#import "GLLASCIIScanner.h"
#import "GLLModelBone.h"
#import "GLLModelObj.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

#import "GLLara-Swift.h"

NSString *GLLModelLoadingErrorDomain = @"GLL Model loading error domain";

@interface GLLModel ()

// Adds a single mesh to the object, splitting it up into multiple parts if necessary (as specified by the model parameters). Also takes care to add it to the mesh groups and so on.
- (void)_addMesh:(GLLModelMesh *)mesh toArray:(NSMutableArray *)array;

@end

static NSCache *cachedModels;

@implementation GLLModel

+ (void)initialize
{
    cachedModels = [[NSCache alloc] init];
}

+ (id)cachedModelFromFile:(NSURL *)file parent:(GLLModel *)parent error:(NSError *__autoreleasing*)error;
{
    id key = file.absoluteString;
    if (parent != nil)
        key = [file.absoluteString stringByAppendingFormat:@"\n%@", parent.baseURL.absoluteString];
    
    id result = [cachedModels objectForKey:key];
    if (!result)
    {
        if ([file.path hasSuffix:@".mesh"] || [file.path hasSuffix:@".xps"])
        {
            result = [[GLLModelXNALara alloc] initWithBinaryFromFile:file parent:parent error:error];
            if (!result) return nil;
        }
        else if ([file.path hasSuffix:@".mesh.ascii"])
        {
            result = [[GLLModelXNALara alloc] initWithASCIIFromFile:file parent:parent error:error];
            if (!result) return nil;
        }
        else if ([file.path hasSuffix:@".obj"])
        {
            result = [[GLLModelObj alloc] initWithContentsOfURL:file error:error];
            if (!result) return nil;
        }
        else if ([file.path hasSuffix:@".gltf"])
        {
            result = [[GLLModelGltf alloc] initWithUrl:file isBinary:NO error:error];
            if (!result) return nil;
        }
        else if ([file.path hasSuffix:@".glb"])
        {
            result = [[GLLModelGltf alloc] initWithUrl:file isBinary:YES error:error];
            if (!result) return nil;
        }
        else
        {
            if (error)
            {
                // Find display name for this extension
                CFStringRef fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) file.pathExtension, NULL);
                CFStringRef fileTypeDescription = UTTypeCopyDescription(fileType);
                CFRelease(fileType);
                
                *error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_FileTypeNotSupported userInfo:@{
                                                                                                                                       NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Files of type %@ are not supported.", @"Tried to load unsupported format"), (__bridge NSString *)fileTypeDescription],
                                                                                                                                       NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Only .mesh, .mesh.ascii and .obj files can be loaded.", @"Tried to load unsupported format")}];
                CFRelease(fileTypeDescription);
            }
            return nil;
        }
        
        [cachedModels setObject:result forKey:key];
    }
    return result;
}

#pragma mark - Accessors

- (BOOL)hasBones
{
    return self.bones.count > 0;
}

- (NSArray<GLLModelBone *> *)rootBones
{
    return [self.bones filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasParent == NO"]];
}

- (NSArray<GLLCameraTargetDescription *> *)cameraTargetNames
{
    return self.parameters.cameraTargets;
}

- (GLLModelBone *)boneForName:(NSString *)name;
{
    return [self.bones firstObjectMatching:^BOOL(GLLModelBone *bone){
        return [bone.name isEqual:name];
    }];
}

#pragma mark - Private methods

- (void)_addMesh:(GLLModelMesh *)mesh toArray:(NSMutableArray *)array;
{
    GLLMeshParams *params = [self.parameters paramsForMesh:mesh.name];
    if (params.splitters.count > 0)
    {
        [array addObjectsFromArray:[params.splitters map:^(GLLMeshSplitter *splitter) {
            return [mesh partialMeshFromSplitter:splitter];
        }]];
    }
    else
    {
        [array addObject:mesh];
    }
}

@end
