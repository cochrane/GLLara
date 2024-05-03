//
//  GLLItemMesh+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItemMesh {
    
    @objc var willLoseDataWhenConvertedToOBJ: Bool {
        return (self.mesh.textures.count > 1) || (self.mesh.textures.count == 1 && self.mesh.textures["diffuseTexture"]?.url == nil) || (self.renderParameters.count > 0)
    }
    
    @objc func writeMTL(baseURL: URL) -> String {
        var result = "newmtl material\(meshIndex)\n"
        
        // Use only first texture and only if it isn't baked into the model file
        // TODO It's probably possible to extract this texture, but does anyone care?
        if let url = mesh.textures["diffuseTexture"]?.url {
            let baseComponents = baseURL.pathComponents
            let textureComponents = url.pathComponents
            
            // Find where the paths diverge
            var commonPathLength = 0
            for i in 0 ..< min(baseComponents.count, textureComponents.count) {
                if baseComponents[i] != textureComponents[i] {
                    break
                } else {
                    commonPathLength = i
                }
            }
            
            var relativePathComponents: [String] = []
            
            // Add .. for any additional path in the base file
            for _ in commonPathLength ..< baseComponents.count - 1 {
                relativePathComponents.append("..")
            }
            
            relativePathComponents.append(contentsOf: textureComponents.dropFirst(commonPathLength))
            
            let relativePath = relativePathComponents.joined(separator: "/")
            result += "map_Kd \(relativePath)\r\n"
        }
        return result
    }
    
    @objc func writeOBJ(transformations: UnsafePointer<mat_float16>, baseIndex: Int, includeColors: Bool) -> String {
        return mesh.writeOBJ(transformations: transformations, baseIndex: baseIndex, includeColors: includeColors)
    }
    
}
