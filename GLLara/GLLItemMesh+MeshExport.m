//
//  GLLItemMesh+MeshExport.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh+MeshExport.h"

#import "GLLItemMeshTexture.h"
#import "GLLFloatRenderParameter.h"
#import "NSArray+Map.h"

#import "GLLara-Swift.h"

@implementation GLLItemMesh (MeshExport)

- (XnaLaraShaderDescription *)shaderDescriptionError:(NSError *__autoreleasing*)error {
    XnaLaraShaderDescription *description = [[self.mesh.model.parameters xnaLaraShaderDescriptions] firstObjectMatching:^BOOL(XnaLaraShaderDescription *description) {
        
        if (![description.baseName isEqual:self.shaderBase]) {
            return NO;
        }
        NSSet<NSString *>* modules = [[NSSet alloc] initWithArray:description.moduleNames];
        if (![modules isEqual:self.shaderModules]) {
            return NO;
        }
        return YES;
    }];
    if (!description && error) {
        *error = [NSError errorWithDomain:@"GLLMeshExporting" code:1 userInfo:@{
                                                                                NSLocalizedDescriptionKey : NSLocalizedString(@"Could not export model.", @"no mesh group found for model to export"),
                                                                                NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"No XNALara Mesh Group number corresponds to the shader %@.", @"can't write meshes without tangents"), @""]}];
    }
    return description;
}

- (NSString *)genericItemNameForShaderDescription:(XnaLaraShaderDescription *)xnaLaraShaderDescription
{
    NSMutableString *genericItemName = [NSMutableString string];
    
    // 1 - get mesh group
    NSArray<NSString *> *possibleGroups = self.mesh.usesAlphaBlending ? xnaLaraShaderDescription.alphaMeshGroups : xnaLaraShaderDescription.solidMeshGroups;
    NSRegularExpression *meshGroupNameRegexp = [NSRegularExpression regularExpressionWithPattern:@"^MeshGroup([0-9]+)$" options:0 error:NULL];
    for (NSString *groupName in possibleGroups)
    {
        NSTextCheckingResult *match = [meshGroupNameRegexp firstMatchInString:groupName options:NSMatchingAnchored range:NSMakeRange(0, groupName.length)];
        if (!match || match.range.location == NSNotFound) continue;
        
        [genericItemName appendString:[groupName substringWithRange:[match rangeAtIndex:1]]];
        [genericItemName appendString:@"_"];
        break;
    }
    
    NSAssert(genericItemName.length > 0, @"Did not find group for mesh %@", self.displayName);
    
    // 2 - add display name, removing all underscores and newlines
    NSCharacterSet *illegalSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r_"];
    [genericItemName appendString:[[self.displayName componentsSeparatedByCharactersInSet:illegalSet] componentsJoinedByString:@"-"]];
    
    // 3 - write required parameters
    for (NSArray<NSString *>* renderParameterNames in xnaLaraShaderDescription.parameterUniformsInOrder)
    {
        GLLFloatRenderParameter *param = (GLLFloatRenderParameter *) [self renderParameterWithName:renderParameterNames[0]];
        NSAssert(param && [param isMemberOfClass:[GLLFloatRenderParameter class]], @"Object has to have parameter %@ and it must be float", renderParameterNames[0]);
        
        [genericItemName appendFormat:@"_%f", param.value];
    }
    
    return genericItemName;
}

- (NSArray<NSURL *> *)textureUrlsForDescription:(XnaLaraShaderDescription *)xnaLaraShaderDescription
{
    return [xnaLaraShaderDescription.textureUniformsInOrder map:^(NSString *textureName){
        return [self textureWithIdentifier:textureName].textureURL;
    }];
}

- (NSString *)writeASCIIError:(NSError *__autoreleasing*)error;
{
    XnaLaraShaderDescription *description = [self shaderDescriptionError:error];
    if (!description) return nil;
    return [self.mesh writeAsciiWithName:[self genericItemNameForShaderDescription:description] texture:[self textureUrlsForDescription:description]];
}
- (NSData *)writeBinaryError:(NSError *__autoreleasing*)error;
{
    XnaLaraShaderDescription *description = [self shaderDescriptionError:error];
    if (!description) return nil;
    return [self.mesh writeBinaryWithName:[self genericItemNameForShaderDescription:description] texture:[self textureUrlsForDescription:description]];
}

- (BOOL)shouldExport
{
    return self.isVisible && ([self shaderDescriptionError:NULL] != nil);
}

@end
