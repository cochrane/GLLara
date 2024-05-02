//
//  GLLItem.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

#import "GLLItemBone.h"
#import "GLLItemMesh.h"
#import "simd_matrix.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"
#import "NSArray+Map.h"

#import "GLLara-Swift.h"

@interface GLLItem ()
{
    NSOrderedSet* cachedCombinedBones;
    id childItemsObserver;
}

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
- (void)_updateTransform;

@end

@implementation GLLItem

@dynamic displayName;
@dynamic itemURLBookmark;
@dynamic scaleX;
@dynamic scaleY;
@dynamic scaleZ;
@dynamic rotationX;
@dynamic rotationY;
@dynamic rotationZ;
@dynamic positionX;
@dynamic positionY;
@dynamic positionZ;
@dynamic isVisible;
@dynamic bones;
@dynamic meshes;
@dynamic normalChannelAssignmentR;
@dynamic normalChannelAssignmentG;
@dynamic normalChannelAssignmentB;
@dynamic parent;

@dynamic model;
@dynamic itemURL;
@dynamic itemDirectory;

@synthesize modelTransform;

#pragma mark - Special accessors
- (void)setPositionX:(float)position
{
    [self _standardSetValue:@(position) forKey:@"positionX"];
    [self _updateTransform];
}
- (void)setPositionY:(float)position
{
    [self _standardSetValue:@(position) forKey:@"positionY"];
    [self _updateTransform];
}
- (void)setPositionZ:(float)position
{
    [self _standardSetValue:@(position) forKey:@"positionZ"];
    [self _updateTransform];
}

- (void)setRotationX:(float)position
{
    [self _standardSetValue:@(position) forKey:@"rotationX"];
    [self _updateTransform];
}
- (void)setRotationY:(float)position
{
    [self _standardSetValue:@(position) forKey:@"rotationY"];
    [self _updateTransform];
}
- (void)setRotationZ:(float)position
{
    [self _standardSetValue:@(position) forKey:@"rotationZ"];
    [self _updateTransform];
}

- (void)setScaleX:(float)position
{
    [self _standardSetValue:@(position) forKey:@"scaleX"];
    [self _updateTransform];
}
- (void)setScaleY:(float)position
{
    [self _standardSetValue:@(position) forKey:@"scaleY"];
    [self _updateTransform];
}
- (void)setScaleZ:(float)position
{
    [self _standardSetValue:@(position) forKey:@"scaleZ"];
    [self _updateTransform];
}

#pragma mark - Non-standard attributes

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }
    
    [self addObserver:self forKeyPath:@"childItems" options:NSKeyValueObservingOptionNew context:0];
    
    return self;
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    // Get URL from bookmark and load that model.
    NSData *bookmarkData = self.itemURLBookmark;
    if (bookmarkData)
    {
        NSURL *itemURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:0 relativeToURL:nil bookmarkDataIsStale:NULL error:NULL];
        [self setPrimitiveValue:itemURL forKey:@"itemURL"];
    }
    
    NSURL *itemURL = self.itemURL;
    if (itemURL)
    {
        NSError *error = nil;
        GLLModel *model = [GLLModel cachedModelFrom:itemURL parent:self.parent.model error:&error];
        if (!model) {
            NSLog(@"Could not load model due to %@", error);
        }
        [self setPrimitiveValue:model forKey:@"model"];
    }
    
    [self _updateTransform];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    [self _updateTransform];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
    [self _updateTransform];
}

- (void)willSave
{
    // Get URL from model, and put that URL in a bookmark.
    GLLModel *model = [self primitiveValueForKey:@"model"];
    NSURL *currentPrimitiveURL = [self primitiveValueForKey:@"itemURL"];
    if (![currentPrimitiveURL isEqual:model.baseURL])
        [self setPrimitiveValue:model.baseURL forKey:@"itemURL"];
    
    NSURL *itemURL = [self primitiveValueForKey:@"itemURL"];
    if (itemURL)
    {
        NSData *bookmark = [itemURL bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
        [self setPrimitiveValue:bookmark forKey:@"itemURLBookmark"];
    }
    else
        [self setPrimitiveValue:nil forKey:@"itemURLBookmark"];
}

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    for (GLLItemBone *bone in self.bones)
    {
        if ([[bone valueForKeyPath:@"items"] count] == 1)
        {
            [self.managedObjectContext deleteObject:bone];
        }
    }
}

- (void)setModel:(GLLModel *)model
{
    [self willChangeValueForKey:@"model"];
    [self setPrimitiveValue:model forKey:@"model"];
    [self didChangeValueForKey:@"model"];
    
    // Replace all mesh settings, bone transformations and camera targets
    // They have appropriate default values, so they need no setting of parameters.
    NSMutableOrderedSet *meshes = [self mutableOrderedSetValueForKey:@"meshes"];
    [meshes removeAllObjects];
    for (NSUInteger i = 0; i < model.meshes.count; i++)
    {
        GLLItemMesh *itemMesh = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMesh" inManagedObjectContext:self.managedObjectContext];
        [itemMesh prepareWithItem: self];
    }
    
    NSMutableOrderedSet *bones = [self mutableOrderedSetValueForKey:@"bones"];
    [bones removeAllObjects];
    for (NSUInteger i = 0; i < model.bones.count; i++)
    {
        GLLItemBone *parentsBone = [self.parent boneForName:[model.bones[i] name]];
        if (parentsBone)
            [bones addObject:parentsBone];
        else
            [bones addObject:[NSEntityDescription insertNewObjectForEntityForName:@"GLLItemBone" inManagedObjectContext:self.managedObjectContext]];
    }
    
    // -- Trigger a rebuild of the matrices
    for (GLLItemBone *bone in bones) {
        if (!bone.parent)
            [bone setPositionX:0];
    }
    
    for (GLLCameraTargetDescription *description in model.cameraTargetNames)
    {
        NSManagedObject *cameraTarget = [NSEntityDescription insertNewObjectForEntityForName:@"GLLCameraTarget" inManagedObjectContext:self.managedObjectContext];
        [cameraTarget setValue:description.name forKey:@"name"];
        for (GLLItemBone *bone in bones)
            if ([description.boneNames containsObject:bone.bone.name])
                [[cameraTarget mutableSetValueForKey:@"bones"] addObject:bone];
    }
    
    // Display name!
    
    // -- Get a base name
    NSURL *modelDirectory = [self.model.baseURL URLByDeletingLastPathComponent];
    NSMutableString *basicName = [[NSMutableString alloc] initWithString:modelDirectory.lastPathComponent];
    
    // -- Remove extensions
    if ([basicName hasSuffix:@".ascii"])
        [basicName deleteCharactersInRange:NSMakeRange(basicName.length - @".ascii".length, @".ascii".length)];
    if ([basicName hasSuffix:@".mesh"])
        [basicName deleteCharactersInRange:NSMakeRange(basicName.length - @".mesh".length, @".mesh".length)];
    
    // -- Replace underscores
    [basicName replaceOccurrencesOfString:@"_" withString:@" " options:0 range:NSMakeRange(0, basicName.length)];
    
    // -- Use title case
    CFStringTransform((__bridge CFMutableStringRef) basicName, NULL, CFSTR("Title"), NO);
    
    // -- Find out how many others with the same name exist
    NSFetchRequest *sameNameRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
    sameNameRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"displayName"] rightExpression:[NSExpression expressionForConstantValue:basicName] modifier:0 type:NSEqualToPredicateOperatorType options:NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:sameNameRequest error:NULL];
    
    // -- Append number if one exists with the same name
    if (count > 0)
        [basicName appendFormat:NSLocalizedString(@" (%lu)", @"same item display name suffix format"), count + 1];
    
    // -- And assign to self.
    self.displayName = [basicName copy];
}

#pragma mark - Derived

- (NSArray<GLLItemBone *> *)rootBones
{
    NSIndexSet *indices = [self.bones indexesOfObjectsPassingTest:^BOOL(GLLItemBone *bone, NSUInteger idx, BOOL *stop) {
        return !bone.parent;
    }];
    return [self.bones objectsAtIndexes:indices];
}

- (GLLItemMesh *)itemMeshForModelMesh:(GLLModelMesh *)mesh;
{
    return self.meshes[mesh.meshIndex];
}

- (GLLItemBone *)boneForName:(NSString *)name;
{
    return [self.bones firstObjectMatching:^BOOL(GLLItemBone *bone) {
        return [bone.bone.name isEqual:name];
    }];
}
- (NSOrderedSet<GLLItemBone *> *)combinedBones;
{
    if (cachedCombinedBones) {
        return cachedCombinedBones;
    }
    NSMutableOrderedSet<GLLItemBone *> *combinedBones = [NSMutableOrderedSet orderedSetWithOrderedSet:[self valueForKeyPath:@"bones"]];
    for (GLLItem *child in [self valueForKeyPath:@"childItems"])
        [combinedBones unionOrderedSet:child.combinedBones];
    
    cachedCombinedBones = combinedBones;
    return cachedCombinedBones;
}
- (NSOrderedSet<GLLItemBone *> *)combinedUsedBones;
{
    NSOrderedSet<GLLItemBone *>* bones = [self valueForKeyPath:@"bones"];
    NSMutableOrderedSet<GLLItemBone *> *combinedBones = [NSMutableOrderedSet orderedSetWithCapacity:bones.count];
    for (GLLItemBone *bone in bones) {
        if (![bone.bone.name hasPrefix:@"unused"]) {
            [combinedBones addObject:bone];
        }
    }
    for (GLLItem *child in [self valueForKeyPath:@"childItems"])
        [combinedBones unionOrderedSet:child.combinedUsedBones];
    
    return combinedBones;
}

- (GLLItem *)rootItem
{
    if (self.parent)
        return self.parent.rootItem;
    else
        return self;
}

- (BOOL)hasOptionalParts {
    for (GLLItemMesh *mesh in self.meshes) {
        if (mesh.mesh.optionalPartNames.count > 0)
            return YES;
    }
    return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqual:@"childItems"] && object == self) {
        cachedCombinedBones = nil;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Poses I/O

- (BOOL)loadPoseFrom:(NSURL *)poseUrl error:(NSError *__autoreleasing*)error; {
    NSString *poseDescription = [NSString stringWithContentsOfURL:poseUrl usedEncoding:NULL error:error];
    
    if (!poseDescription) {
        return NO;
    }
    
    return [self loadPose:poseDescription error:error];
}

- (BOOL)loadPose:(NSString *)poseDescription error:(NSError *__autoreleasing*)error
{
    NSArray *lines = [poseDescription componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if ([poseDescription rangeOfString:@":"].location == NSNotFound)
    {
        // Old-style loading: Same number of lines as bones, sequentally stored, no names.
        if (lines.count != self.bones.count)
        {
            if (error)
                *error = [NSError errorWithDomain:@"poses" code:1 userInfo:@{
                                                                             NSLocalizedDescriptionKey : NSLocalizedString(@"Pose file does not contain the right amount of bones", @"error loading pose old-style"),
                                                                             NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Poses in the old format have to contain exactly as many items as bones. Try using a newer pose.", @"error loading pose old-style")}];
            return NO;
        }
        
        for (NSUInteger i = 0; i < lines.count; i++)
        {
            NSScanner *scanner = [NSScanner scannerWithString:lines[i]];
            float x = 0, y = 0, z = 0;
            if ([scanner scanFloat:&x])
                [self.bones[i] setRotationX:x];
            if ([scanner scanFloat:&y])
                [self.bones[i] setRotationY:y];
            if ([scanner scanFloat:&z])
                [self.bones[i] setRotationZ:z];
        }
    }
    else
    {
        for (NSString *line in lines)
        {
            if (line.length == 0) continue; // May insert empty lines due to Windows line endings.
            
            NSScanner *scanner = [NSScanner scannerWithString:line];
            NSString *name;
            [scanner scanUpToString:@":" intoString:&name];
            [scanner scanString:@":" intoString:NULL];
            
            NSIndexSet *indices = [self.bones indexesOfObjectsPassingTest:^BOOL(GLLItemBone *bone, NSUInteger idx, BOOL *stop) {
                return [bone.bone.name isEqual:name];
            }];
            if (indices.count == 0)
            {
                NSLog(@"Skipping unknown bone %@", name);
                continue;
            }
            GLLItemBone *transform = self.bones[indices.firstIndex];
            
            float x = 0, y = 0, z = 0;
            if ([scanner scanFloat:&x]) transform.rotationX = x * M_PI / 180.0;
            if ([scanner scanFloat:&y]) transform.rotationY = y * M_PI / 180.0;
            if ([scanner scanFloat:&z]) transform.rotationZ = z * M_PI / 180.0;
            
            if ([scanner scanFloat:&x]) transform.positionX = x;
            if ([scanner scanFloat:&y]) transform.positionY = y;
            if ([scanner scanFloat:&z]) transform.positionZ = z;
        }
    }
    return YES;
}

#pragma mark - Private methods

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:value forKey:key];
    [self didChangeValueForKey:key];
}

- (void)_updateTransform;
{
    mat_float16 scale = matrix_from_diagonal(simd_make_float4(self.scaleX, self.scaleY, self.scaleZ, 1.0f));
    mat_float16 rotateAndTranslate = simd_mat_euler(simd_make_float4(self.rotationX, self.rotationY, self.rotationZ, 0.0f), simd_make_float4(self.positionX, self.positionY, self.positionZ, 1.0f));
    
    modelTransform = simd_mul(rotateAndTranslate, scale);
    [self.rootBones makeObjectsPerformSelector:@selector(updateGlobalTransform)];
}

@end
