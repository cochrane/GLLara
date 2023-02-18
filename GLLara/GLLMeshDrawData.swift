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
    let boneDataArray: MTLBuffer?
    let boneIndexOffset: Int?
    let reservation: GLLVertexArray.Reservation
    
    init(mesh: GLLModelMesh, vertexArray array: GLLVertexArray, resourceManager: GLLResourceManager) {
        modelMesh = mesh
        self.vertexArray = array
        
        reservation = array.reserve(vertexCount: modelMesh.countOfVertices, elements: modelMesh.elementData, bytesPerElement: modelMesh.elementSize)
        
        indicesStart = reservation.elementBytesStart
        baseVertex = reservation.baseVertex
        elementType = vertexArray.format.indexType
        if vertexArray.format.hasIndices {
            elementsOrVerticesCount = mesh.countOfElements
        } else {
            elementsOrVerticesCount = mesh.countOfVertices
        }
        
        if let boneIndices = mesh.variableBoneIndices, let boneWeights = mesh.variableBoneWeights {
            let weightsSize = MemoryLayout<Float>.stride * boneWeights.count
            let indicesSize = MemoryLayout<UInt16>.stride * boneIndices.count
            
            boneDataArray = resourceManager.metalDevice.makeBuffer(length: weightsSize + indicesSize, options: .storageModeShared)
            boneDataArray!.contents().copyMemory(from: boneWeights, byteCount: weightsSize)
            boneDataArray!.contents().advanced(by: weightsSize).copyMemory(from: boneIndices, byteCount: indicesSize)
            boneDataArray!.label = mesh.displayName + "-bonedata"
            boneIndexOffset = weightsSize
        } else {
            boneDataArray = nil
            boneIndexOffset = nil
        }
    }
    
    func addToVertexArray() {
        vertexArray.add(vertices: modelMesh.vertexDataAccessors!, count: modelMesh.countOfVertices, elements: modelMesh.elementData, bytesPerElement: modelMesh.elementSize, at: reservation)
    }
    
}
