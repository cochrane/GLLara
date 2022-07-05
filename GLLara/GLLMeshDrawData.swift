//
//  GLLMeshDrawData.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

class GLLMeshDrawData {
    
    let modelMesh: GLLModelMesh
    
    let elementType: MTLIndexType
    let baseVertex: Int
    let indicesStart: Int
    let elementsOrVerticesCount: Int
    let vertexArray: GLLVertexArray
    
    init(mesh: GLLModelMesh, vertexArray array: GLLVertexArray, resourceManager: GLLResourceManager) {
        modelMesh = mesh
        self.vertexArray = array
        
        indicesStart = vertexArray.elementDataLength
        baseVertex = vertexArray.countOfVertices
        elementType = vertexArray.format.indexType
        if vertexArray.format.hasIndices {
            elementsOrVerticesCount = mesh.countOfElements
        } else {
            elementsOrVerticesCount = mesh.countOfVertices
        }
        
        vertexArray.add(vertices: mesh.vertexDataAccessors!, count: mesh.countOfVertices, elements: mesh.elementData, bytesPerElement: mesh.elementSize)
    }
    
}
