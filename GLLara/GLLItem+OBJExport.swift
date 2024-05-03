//
//  GLLItem+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItem {
    @objc var willLoseDataWhenConvertedToOBJ: Bool {
        return meshes.first { ($0 as! GLLItemMesh).willLoseDataWhenConvertedToOBJ } != nil
    }
    
    @objc func writeOBJ(location: URL, transform: Bool, color: Bool) throws {
        var string = ""
        
        let materialLibraryName = location.deletingPathExtension().appendingPathExtension(".mtl").lastPathComponent
        string += "usemtl \(materialLibraryName)\r\n"
        
        var transforms = Array<mat_float16>(repeating: mat_float16(), count: bones.count)
        var boneIndex = 0
        for bone in bones {
            if transform {
                transforms[boneIndex] = (bone as! GLLItemBone).globalTransform
            } else {
                transforms[boneIndex] = (bone as! GLLItemBone).bone.positionMatrix
            }
            boneIndex += 1
        }
        
        var indexOffset = 0
        for mesh in meshes {
            string += (mesh as! GLLItemMesh).writeOBJ(transformations: transforms, baseIndex: indexOffset, includeColors: color)
            indexOffset += (mesh as! GLLItemMesh).mesh.countOfVertices
        }
        try string.write(to: location, atomically: true, encoding: .utf8)
    }
    
    @objc func writeMTL(location: URL) throws {
        let content = meshes.map { ($0 as! GLLItemMesh).writeMTL(baseURL: location) }.joined(separator: "\r\n")
        try content.write(to: location, atomically: true, encoding: .utf8)
    }
}
