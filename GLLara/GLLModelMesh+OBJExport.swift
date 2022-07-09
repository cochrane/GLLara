//
//  GLLModelMesh+OBJExport.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLModelMesh {
    
    @objc func writeOBJ(transformations: UnsafePointer<mat_float16>, baseIndex: Int, includeColors: Bool) -> String {
        
        var objString = ""
        let groupName = name.components(separatedBy: CharacterSet.whitespacesAndNewlines).joined(separator: "_")
        objString.append("g \(groupName)\n")
        objString.append("usemtl material\(meshIndex)")
        
        let positionAccessor = vertexDataAccessors!.accessor(semantic: .position)!
        let normalAccessor = vertexDataAccessors!.accessor(semantic: .normal)!
        let texCoordAccessor = vertexDataAccessors!.accessor(semantic: .texCoord0, layer: 0)!
        let colorAccessor = vertexDataAccessors!.accessor(semantic: .color)!
        let boneIndexAccessor = vertexDataAccessors!.accessor(semantic: .boneIndices)
        let boneWeightAccessor = vertexDataAccessors!.accessor(semantic: .boneWeights)
        
        for i in 0..<countOfVertices {
            let position = positionAccessor.simd3Element(at: i, base: Float32.self)
            let normal = normalAccessor.simd3Element(at: i, base: Float.self)
            
            var transform = transformations[0]
            if let boneIndexAccessor = boneIndexAccessor, let boneWeightAccessor = boneWeightAccessor {
                let boneIndices = boneIndexAccessor.typedElementArray(at: i, type: UInt16.self)
                let boneWeights = boneWeightAccessor.typedElementArray(at: i, type: Float.self)
                
                transform = simd_linear_combination(boneWeights[0], transformations[Int(boneIndices[0])], boneWeights[1], transformations[Int(boneIndices[1])]) + simd_linear_combination(boneWeights[2], transformations[Int(boneIndices[2])], boneWeights[3], transformations[Int(boneIndices[3])])
            }
            
            let transformedPosition = simd_mul(transform, vec_float4(position, 1.0))
            let transformedNormal = simd_mat_vecrotate(transform, vec_float4(normal, 0.0))
            
            objString.append("v \(transformedPosition.x) \(transformedPosition.y) \(transformedPosition.z)")
            
            objString.append("vn \(transformedNormal.x) \(transformedNormal.y) \(transformedNormal.z)")
            
            let texCoords = texCoordAccessor.typedElementArray(at: i, type: Float.self)
            objString.append("vt \(texCoords[0]) \(1.0 - texCoords[1])") // Turn tex coords around (because I don't want to swap the whole image)
            
            if includeColors {
                let color = colorAccessor.typedElementArray(at: i, type: UInt8.self)
                let r = Double(color[0]) / 255.0
                let g = Double(color[1]) / 255.0
                let b = Double(color[2]) / 255.0
                let a = Double(color[3]) / 255.0
                objString.append("vc \(r) \(g) \(b) \(a)")
            }
        }
        
        for i in stride(from: 0, to: countOfUsedElements, by: 3) {
            let adjustedElements = [
                element(at: i + 0) + baseIndex + 1,
                element(at: i + 2) + baseIndex + 1,
                element(at: i + 1) + baseIndex + 1
            ]
            objString.append("f")
            if includeColors {
                for element in adjustedElements {
                    objString.append(" \(element)/\(element)/\(element)/\(element)")
                }
            } else {
                for element in adjustedElements {
                    objString.append(" \(element)/\(element)/\(element)")
                }
            }
            objString.append("\n")
        }
        
        return objString
    }
    
}
