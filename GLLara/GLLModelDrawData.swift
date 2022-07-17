//
//  GLLModelDrawData.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

class GLLModelDrawData {
    
    private let model: GLLModel
    private weak var resourceManager: GLLResourceManager?
    
    let meshDrawData: [GLLMeshDrawData]
    
    init(model: GLLModel, resourceManager: GLLResourceManager) {
        self.model = model
        self.resourceManager = resourceManager
        
        var vertexArrayMap: [GLLVertexFormat: GLLVertexArray] = [:]
        
        meshDrawData = model.meshes.map { mesh in
            let array: GLLVertexArray
            if let existing = vertexArrayMap[mesh.vertexFormat!] {
                array = existing
            } else {
                array = GLLVertexArray(format: mesh.vertexFormat!)
                vertexArrayMap[mesh.vertexFormat!] = array
            }
            array.debugLabel += "-" + mesh.displayName
            
            return GLLMeshDrawData(mesh: mesh, vertexArray: array, resourceManager: resourceManager)
        }
        
        for array in vertexArrayMap.values {
            array.upload()
        }
    }
    
}
