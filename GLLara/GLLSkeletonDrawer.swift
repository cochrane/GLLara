//
//  GLLSkeletonDrawer.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

@objc class GLLSkeletonDrawer: NSObject {
    
    let device: MTLDevice
    let pipeline: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    
    var defaultColor = NSColor.yellow.withAlphaComponent(0.5)
    var selectedColor = NSColor.red.withAlphaComponent(0.5)
    var childOfSelectedColor = NSColor.green.withAlphaComponent(0.5)
    
    private var verticesBuffer: MTLBuffer
    private var elementsBuffer: MTLBuffer
    
    private var buffersNeedUpdate = true
    
    private var numberOfPoints = 0
    
    @objc init(resourceManager: GLLResourceManager) {
        device = resourceManager.metalDevice
        let library = resourceManager.library
        
        let values = MTLFunctionConstantValues()
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = false
        depthDescriptor.depthCompareFunction = .always
        depthDescriptor.label = "skeleton-depthstate"
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Skeleton"
        pipelineDescriptor.vertexFunction = try! library.makeFunction(name: "skeletonVertex", constantValues: values)
        pipelineDescriptor.fragmentFunction = try! library.makeFunction(name: "skeletonFragment", constantValues: values)
        pipelineDescriptor.colorAttachments[0].pixelFormat = resourceManager.pixelFormat;
        pipelineDescriptor.label = "skeleton-pipeline"
        
        pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        verticesBuffer = device.makeBuffer(length: GLLSkeletonDrawer.vertexCapacity(for: 512), options: .storageModeManaged)!
        verticesBuffer.label = "skeleton-vertices"
        elementsBuffer = device.makeBuffer(length: GLLSkeletonDrawer.elementCapacity(for: 512), options: .storageModeManaged)!
        elementsBuffer.label = "skeleton-elements"
        
        super.init()
        
        settingsChangedNotification = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.displayedBones.removeAll()
        }
    }
    
    private static func elementCapacity(for boneCount: Int) -> Int {
        return boneCount * 2 * MemoryLayout<UInt16>.stride
    }
    
    private static func vertexCapacity(for boneCount: Int) -> Int {
        return boneCount * MemoryLayout<GLLSkeletonDrawerVertex>.stride
    }
    
    private var bufferCapacity: Int {
        return verticesBuffer.length / MemoryLayout<GLLSkeletonDrawerVertex>.stride;
    }
    
    /// The selection. Stores only the root items for anything selected.
    private var selection: [GLLItem: [GLLItemBone]] = [:]
    private var selectionObservers: [NSKeyValueObservation] = []
    
    // A private cache of which bones to display. Asking dynamically takes way too long
    private var displayedBones: [GLLItem: NSOrderedSet] = [:]
    private var settingsChangedNotification: NSObjectProtocol? = nil
    
    @objc var selectedBones: [GLLItemBone] {
        get {
            return selection.values.reduce(Array<GLLItemBone>(), { list, new in list + new })
        }
        set {
            selection.removeAll()
            selectionObservers.removeAll()
            for bone in newValue {
                let root = bone.item.root!
                if let existing = selection[root] {
                    selection[root] = existing + [bone]
                } else {
                    selection[root] = [bone]
                    for entry in root.combinedBones() {
                        let anyBone = entry as! GLLItemBone
                        selectionObservers.append(anyBone.observe(\.globalTransformValue, changeHandler: { [weak self] _,_ in
                            self?.buffersNeedUpdate = true
                        }))
                    }
                }
            }
            displayedBones.removeAll()
            buffersNeedUpdate = true
        }
    }
    
    private func toRgba8(color: NSColor) -> vector_uchar4 {
        return vector_uchar4(UInt8(color.redComponent * 255.0),
                             UInt8(color.greenComponent * 255.0),
                             UInt8(color.blueComponent * 255.0),
                             UInt8(color.alphaComponent * 255.0))
    }
    
    private func updateBuffers() {
        if selection.isEmpty {
            return
        }
        if displayedBones.isEmpty {
            let hideUnused = UserDefaults.standard.bool(forKey: GLLPrefHideUnusedBones)
            for item in selection.keys {
                if hideUnused {
                    displayedBones[item] = item.combinedUsedBones()!
                } else {
                    displayedBones[item] = item.combinedBones()!
                }
            }
        }
        
        let numberOfBones = selection.keys.reduce(0, { count, item in count + displayedBones[item]!.count })
        numberOfPoints = 2*numberOfBones
        
        if numberOfPoints > bufferCapacity {
            // Double or increase to new count, whichever is larger
            let newCount = max(numberOfPoints, bufferCapacity*2)
            verticesBuffer = device.makeBuffer(length: GLLSkeletonDrawer.vertexCapacity(for: newCount), options: .storageModeManaged)!
            verticesBuffer.label = "skeleton-vertices"
            elementsBuffer = device.makeBuffer(length: GLLSkeletonDrawer.elementCapacity(for: newCount), options: .storageModeManaged)!
            elementsBuffer.label = "skeleton-elements"
        }
        
        // Update vertices
        let vertices = verticesBuffer.contents().bindMemory(to: GLLSkeletonDrawerVertex.self, capacity: verticesBuffer.length)
        var offset = 0
        let elements = elementsBuffer.contents().bindMemory(to: UInt16.self, capacity: elementsBuffer.length)
        
        let colorSelected = toRgba8(color: selectedColor)
        let colorChild = toRgba8(color: childOfSelectedColor)
        let colorDefault = toRgba8(color: defaultColor)
        
        var elementsBase = 0
        for item in selection.keys {
            var relativeOffset = 0
            let bones = displayedBones[item]!
            for element in bones {
                let bone = element as! GLLItemBone
                
                let position = bone.globalPosition
                vertices[offset].position.x = simd_extract(position, 0)
                vertices[offset].position.y = simd_extract(position, 1)
                vertices[offset].position.z = simd_extract(position, 2)
                
                if selection.values.contains(where: { $0.contains(bone) }) {
                    vertices[offset].color = colorSelected;
                } else if bone.isChild(ofAny: self.selectedBones) {
                    vertices[offset].color = colorChild
                } else {
                    vertices[offset].color = colorDefault
                }
                
                let start = UInt16(relativeOffset + elementsBase);
                elements[offset * 2 + 0] = start
                let parentIndex = bones.index(of: bone.parent as Any)
                if parentIndex != NSNotFound {
                    elements[offset * 2 + 1] = UInt16(parentIndex + elementsBase)
                } else {
                    // Has no parent, copy over
                    elements[offset * 2 + 1] = start
                }
                
                relativeOffset += 1
                offset += 1
            }
            elementsBase += bones.count
        }
        verticesBuffer.didModifyRange(0 ..< offset * MemoryLayout<GLLSkeletonDrawerVertex>.stride)
        elementsBuffer.didModifyRange(0 ..< offset * 2 * MemoryLayout<UInt16>.stride)
        
        buffersNeedUpdate = false;
    }
    
    @objc func draw(into commandEncoder: MTLRenderCommandEncoder) {
        if buffersNeedUpdate {
            updateBuffers()
        }
        guard numberOfPoints > 0 else {
            return
        }
        
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: Int(GLLVertexInputIndexVertices.rawValue))
        commandEncoder.setDepthStencilState(depthState)
        commandEncoder.drawIndexedPrimitives(type: .line, indexCount: numberOfPoints, indexType: .uint16, indexBuffer: elementsBuffer, indexBufferOffset: 0)
    }
    
}
