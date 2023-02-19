//
//  GLLItem+MeshExport.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItem+MeshExport.h"

#import "GLLItemBone.h"
#import "GLLItemMesh+MeshExport.h"
#import "TROutDataStream.h"

#import "GLLara-Swift.h"

@implementation GLLItem (MeshExport)

- (NSData *)writeBinaryError:(NSError *__autoreleasing*)error;
{
    TROutDataStream *stream = [[TROutDataStream alloc] init];
    
    [stream appendUint32:(uint32_t) self.bones.count];
    for (GLLItemBone *bone in self.bones)
        [stream appendData:[bone.bone writeBinary]];
    
    NSArray *toExport = [self.meshes.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"shouldExport == YES"]];
    [stream appendUint32:(uint32_t) toExport.count];
    for (GLLItemMesh *mesh in toExport)
    {
        NSData *meshData = [mesh writeBinaryError:error];
        if (!meshData) return nil;
        [stream appendData:meshData];
    }
    
    return stream.data;
}
- (NSString *)writeASCIIError:(NSError *__autoreleasing*)error;
{
    NSMutableString *string = [NSMutableString string];
    
    [string appendFormat:@"%lu\n", self.bones.count];
    for (GLLItemBone *bone in self.bones)
        [string appendFormat:@"%@\n", [bone.bone writeASCII]];
    
    NSArray *toExport = [self.meshes.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"shouldExport == YES"]];
    [string appendFormat:@"%lu\n", toExport.count];
    for (GLLItemMesh *mesh in toExport)
    {
        NSString *meshString = [mesh writeASCIIError:error];
        if (!meshString) return nil;
        [string appendFormat:@"%@\n", meshString];
    }
    
    return string;
}

@end
