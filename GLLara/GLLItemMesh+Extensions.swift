//
//  GLLItemMesh+Extensions.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItemMesh {
    @objc func renderParameter(name: String) -> GLLRenderParameter? {
        return renderParameters.first { $0.name == name }
    }
    
    @objc func texture(identifier: String) -> GLLItemMeshTexture? {
        return textures.first { $0.identifier == identifier }
    }
    
    @objc var isUsingBlending: Bool {
        get {
            if isCustomBlending {
                return isBlended
            } else {
                return mesh.usesAlphaBlending
            }
        }
        set {
            isCustomBlending = true
            isBlended = newValue
        }
    }
    
    @objc var mesh: GLLModelMesh {
        return item.model.meshes[Int(meshIndex)]
    }
}
