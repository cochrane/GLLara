//
//  GLLItemDrawer.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

@objc class GLLItemDrawer: NSObject {
    @objc let item: GLLItem
    weak var sceneDrawer: GLLSceneDrawer?
    var needUpdateTransforms = true
    @objc var replacedTextures: [URL:Error] = [:]
    var meshStates: [GLLItemMeshState] = []
    
    private let transformsBuffer: MTLBuffer
    private var observations: [NSKeyValueObservation] = []
    
    @objc init(item: GLLItem, sceneDrawer: GLLSceneDrawer) throws {
        self.item = item
        self.sceneDrawer = sceneDrawer
        
        // Prepare buffer
        let matrixCount = 1 + item.bones.count
        transformsBuffer = sceneDrawer.resourceManager.metalDevice.makeBuffer(length: matrixCount * MemoryLayout<matrix_float4x4>.stride, options: .storageModeManaged)!
        transformsBuffer.label = item.displayName + "-transforms"
        
        // Prepare draw data
        let drawData = try sceneDrawer.resourceManager.drawData(for: item.model)
        
        super.init()
        
        // Observe channel assignments
        let updateTransformsHandler = { [weak self] (item: GLLItem, change: NSKeyValueObservedChange<Int16>) -> Void in
            self?.markUpdateTransforms()
        }
        observations.append(item.observe(\.normalChannelAssignmentR, options: .new, changeHandler: updateTransformsHandler))
        observations.append(item.observe(\.normalChannelAssignmentG, options: .new, changeHandler: updateTransformsHandler))
        observations.append(item.observe(\.normalChannelAssignmentB, options: .new, changeHandler: updateTransformsHandler))
        
        // Observe all the bones
        let updateBoneHandler = { [weak self] (item: GLLItemBone, change: NSKeyValueObservedChange<mat_float16>) -> Void in
            self?.markUpdateTransforms()
        }
        for boneItem in item.bones {
            let bone = boneItem as! GLLItemBone
            observations.append(bone.observe(\.globalTransform, options: .new, changeHandler: updateBoneHandler))
        }
        
        // Observe the settings of all the meshes
        var replacedTextures: [String: Error] = [:]
        for meshData in drawData.meshDrawData {
            let meshState = try GLLItemMeshState(itemDrawer: self, meshData: meshData, itemMesh: item.itemMesh(for: meshData.modelMesh))
            let failedTextures = meshState.updateTextures()
            replacedTextures.merge(failedTextures, uniquingKeysWith: { a, b in return b })
            meshStates.append(meshState)
        }
        
        // TODO All the actual setup stuff like finding runs
        // Which we probably don't need to anymore with metal
        // Just setup whatever we need to make drawSolid and drawAlpha do the right things
        // And also update those
    }
    
    var resourceManager: GLLResourceManager {
        return sceneDrawer!.resourceManager
    }
    
    private func markUpdateTransforms() {
        needUpdateTransforms = true
        propertiesChanged()
    }
    
    func propertiesChanged() {
        sceneDrawer?.notifyRedraw()
    }
    
    private func permutationTableColumn(for assignment: GLLItemChannelAssignment) -> vector_float4 {
        switch assignment {
        case .normalPos: return vector_float4(0, 0, 1, 0)
        case .normalNeg: return vector_float4(0, 0, -1, 0)
        case .tangentUPos: return vector_float4(0, 1, 0, 0)
        case .tangentUNeg: return vector_float4(0, -1, 0, 0)
        case .tangentVPos: return vector_float4(1, 0, 0, 0)
        case .tangentVNeg: return vector_float4(-1, 0, 0, 0)
        @unknown default:
            assertionFailure()
            return vector_float4(0, 0, 0, 0)
        }
    }
    
    private func updateTransforms() {
        let bones = item.bones!
        let boneCount = bones.count
        let matrixCount = 1 + boneCount
        let matrices = transformsBuffer.contents().bindMemory(to: matrix_float4x4.self, capacity: matrixCount)
        
        // First matrix stores the transform for the normals
        matrices[0].columns.0 = permutationTableColumn(for: GLLItemChannelAssignment(rawValue: item.normalChannelAssignmentR)!)
        matrices[0].columns.1 = permutationTableColumn(for: GLLItemChannelAssignment(rawValue: item.normalChannelAssignmentG)!)
        matrices[0].columns.2 = permutationTableColumn(for: GLLItemChannelAssignment(rawValue: item.normalChannelAssignmentB)!)
        matrices[0].columns.3 = vector_float4(0, 0, 0, 1)
        
        for i in 0..<boneCount {
            let bone = bones[i] as! GLLItemBone
            matrices[1 + i] = bone.globalTransform
        }
        transformsBuffer.didModifyRange(0 ..< MemoryLayout<matrix_float4x4>.stride * matrixCount)
        
        needUpdateTransforms = false
    }
    
    @objc func drawSolid(into commandEncoder: MTLRenderCommandEncoder) {
        if (needUpdateTransforms) {
            updateTransforms()
        }
        
        commandEncoder.setVertexBuffer(transformsBuffer, offset: 0, index: Int(GLLVertexInputIndexTransforms.rawValue))
        
        for meshState in meshStates {
            meshState.render(into: commandEncoder)
        }
    }
}
