//
//  GLLItemMeshState.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal
import simd

extension GLLRenderParameter {
    var floatValue: Float32 {
        assert(uniformValue.count == MemoryLayout<Float32>.size, "Not a float")
        var result = Float32(0)
        _ = withUnsafeMutableBytes(of: &result) { uniformValue.copyBytes(to: $0) }
        return result
    }
    
    var colorValue: vector_float4 {
        assert(uniformValue.count == MemoryLayout<vector_float4>.size, "Not a float4")
        var result = vector_float4(repeating: 0)
        _ = withUnsafeMutableBytes(of: &result) { uniformValue.copyBytes(to: $0) }
        return result
    }
}

class GLLItemMeshState {
    let drawer: GLLItemDrawer
    let itemMesh: GLLItemMesh
    let meshData: GLLMeshDrawData
    
    var texturesForResourceIds: [Int: MTLTexture] = [:]
    var pipelineStateInformation: GLLPipelineStateInformation? = nil
    var fragmentArgumentBuffer: MTLBuffer? = nil
    
    private var observations: [NSKeyValueObservation] = []
    private var textureObservations: [NSKeyValueObservation] = []
    private var renderParameterObservations: [NSKeyValueObservation] = []
    private var needsTextureUpdate = true
    private var argumentsEncoder: MTLArgumentEncoder? = nil
    
    init(itemDrawer: GLLItemDrawer, meshData: GLLMeshDrawData, itemMesh: GLLItemMesh) throws {
        drawer = itemDrawer
        self.itemMesh = itemMesh
        self.meshData = meshData
        
        updatePipelineState()
        
        observations.append(itemMesh.observe(\.shader) { [weak self] _,_ in
            self?.needsTextureUpdate = true
            self?.updatePipelineState()
            self?.drawer.propertiesChanged()
        })
        observations.append(itemMesh.observe(\.isVisible) { [weak self] _,_ in
            self?.drawer.propertiesChanged()
        })
        observations.append(itemMesh.observe(\.isUsingBlending) { [weak self] _,_ in
            self?.updatePipelineState()
            self?.drawer.propertiesChanged()
        })
        observations.append(itemMesh.observe(\.textures) { [weak self] _,_ in
            _ = self?.updateTextureObjects()
        })
        observations.append(itemMesh.observe(\.renderParameters) { [weak self] _,_ in
            _ = self?.updateParameterObjects()
        })
        
    }
    
    private func updateTextureObjects() {
        textureObservations.removeAll()
        
        guard let newTextures = itemMesh.textures else {
            return
        }
        
        for itemMeshTexture in newTextures {
            textureObservations.append(itemMeshTexture.observe(\.textureURL) { [weak self] _,_ in
                self?.needsTextureUpdate = true
                self?.drawer.propertiesChanged()
            })
            textureObservations.append(itemMeshTexture.observe(\.texCoordSet) { [weak self] _,_ in
                self?.updatePipelineState()
                self?.drawer.propertiesChanged()
            })
        }
    }
    
    private func updateParameterObjects() {
        renderParameterObservations.removeAll()
        
        guard let newRenderParameters = itemMesh.renderParameters else {
            return;
        }
        
        for parameter in newRenderParameters {
            renderParameterObservations.append(parameter.observe(\.uniformValue) { [weak self] _,_ in
                self?.updateArgumentBuffer()
                self?.drawer.propertiesChanged()
            })
        }
    }
    
    private func loadTexture(identifier: String) throws -> GLLTexture {
        let textureAssignment = itemMesh.texture(withIdentifier: identifier)
        
        if let url = textureAssignment?.textureURL {
            // Load from the given URL (where possible
            return try drawer.resourceManager.texture(url: url)
        } else if let data = itemMesh.mesh.textures[identifier]?.data {
            // Load what the model provided
            return try GLLTexture(data: data, sourceURL: itemMesh.mesh.model!.baseURL, device: drawer.resourceManager.metalDevice)
        }
        throw NSError(domain: "Textures", code: 100, userInfo: [ NSLocalizedDescriptionKey: String(format: NSLocalizedString("No texture file provided for identifier %@", comment: "Texture data is missing"), identifier) ])
    }
    
    private func textureIndex(for identifier: String) -> Int {
        switch identifier {
        case "diffuseTexture":
            return Int(GLLFragmentArgumentIndexTextureDiffuse.rawValue)
        case "specularTexture":
            return Int(GLLFragmentArgumentIndexTextureSpecular.rawValue)
        case "emissionTexture":
            return Int(GLLFragmentArgumentIndexTextureEmission.rawValue)
        case "bumpTexture":
            return Int(GLLFragmentArgumentIndexTextureBump.rawValue)
        case "bump1Texture":
            return Int(GLLFragmentArgumentIndexTextureBump1.rawValue)
        case "bump2Texture":
            return Int(GLLFragmentArgumentIndexTextureBump2.rawValue)
        case "maskTexture":
            return Int(GLLFragmentArgumentIndexTextureMask.rawValue)
        case "lightmapTexture":
            return Int(GLLFragmentArgumentIndexTextureLightmap.rawValue)
        case "reflectionTexture":
            return Int(GLLFragmentArgumentIndexTextureReflection.rawValue)
        default:
            assertionFailure("Unknown texture type")
            return Int(GLLFragmentArgumentIndexTextureDiffuse.rawValue)
        }
    }
    
    private func parameterColor(name: String, defaultValue: SIMD4<Float32>) -> SIMD4<Float32> {
        guard let parameter = itemMesh.renderParameter(withName: name) else {
            return defaultValue
        }
        
        return parameter.colorValue
    }
    
    private func assignParameterColor(name: String, defaultValue: SIMD4<Float32>, encoder: MTLArgumentEncoder, index: GLLFragmentArgumentIndex) {
        let buffer = encoder.constantData(at: Int(index.rawValue)).bindMemory(to: SIMD4<Float32>.self, capacity: 1)
        buffer[0] = parameterColor(name: name, defaultValue: defaultValue)
    }
    
    private func parameterFloat(name: String, defaultValue: Float32) -> Float32 {
        guard let parameter = itemMesh.renderParameter(withName: name) else {
            return defaultValue
        }
        
        return parameter.floatValue
    }
    
    private func assignParameterFloat(name: String, defaultValue: Float32, encoder: MTLArgumentEncoder, index: GLLFragmentArgumentIndex) {
        let buffer = encoder.constantData(at: Int(index.rawValue)).bindMemory(to: Float32.self, capacity: 1)
        buffer[0] = parameterFloat(name: name, defaultValue: defaultValue)
    }
    
    private func updateArgumentBuffer() {
        guard let pipelineStateInformation = pipelineStateInformation else {
            return
        }
        
        if argumentsEncoder == nil {
            argumentsEncoder = pipelineStateInformation.fragmentProgram.makeArgumentEncoder(bufferIndex: Int(GLLFragmentBufferIndexArguments.rawValue))
        }
        guard let encoder = argumentsEncoder else {
            return
        }
        
        let size = encoder.encodedLength
        
        if fragmentArgumentBuffer?.allocatedSize ?? 0 < size {
            fragmentArgumentBuffer = drawer.resourceManager.metalDevice.makeBuffer(length: size, options: [])
            fragmentArgumentBuffer?.label = itemMesh.displayName + "-arguments"
        }
        
        encoder.setArgumentBuffer(fragmentArgumentBuffer, offset: 0)
        
        // Set textures
        for (resourceId, texture) in texturesForResourceIds {
            encoder.setTexture(texture, index: resourceId)
        }
        
        // Set render parameters
        // - first the colors, ambient, diffuse, specular
        assignParameterColor(name: "ambientColor", defaultValue: vector_float4(repeating: 1.0), encoder: encoder, index: GLLFragmentArgumentIndexAmbientColor)
        assignParameterColor(name: "diffuseColor", defaultValue: vector_float4(repeating: 1.0), encoder: encoder, index: GLLFragmentArgumentIndexDiffuseColor)
        
        // Specular color gets special treatment - bumpSpecularAmount gets folded into specularColor
        let specularColorBuffer = encoder.constantData(at: Int(GLLFragmentArgumentIndexSpecularColor.rawValue)).bindMemory(to: SIMD4<Float32>.self, capacity: 1)
        let specularColorValue = parameterColor(name: "specularColor", defaultValue: vector_float4(repeating: 1.0))
        let specularIntensityValue = parameterFloat(name: "bumpSpecularAmount", defaultValue: 1.0)
        specularColorBuffer[0] = specularColorValue * specularIntensityValue
        
        // Specular exponent also gets special treatment - there are two different ways to refer to it
        let specularExponentBuffer = encoder.constantData(at: Int(GLLFragmentArgumentIndexSpecularExponent.rawValue)).bindMemory(to: Float32.self, capacity: 1)
        let specularExponentValue = parameterFloat(name: "specularExponent", defaultValue: 0.0)
        let bumpSpecularAmountValue = parameterFloat(name: "bumpSpecularGloss", defaultValue: 0.0)
        specularExponentBuffer[0] = max(specularExponentValue, bumpSpecularAmountValue)
        
        // - Then the normal floats
        assignParameterFloat(name: "bump1UVScale", defaultValue: 1.0, encoder: encoder, index: GLLFragmentArgumentIndexBump1UVScale)
        assignParameterFloat(name: "bump2UVScale", defaultValue: 1.0, encoder: encoder, index: GLLFragmentArgumentIndexBump2UVScale)
        assignParameterFloat(name: "specularTextureScale", defaultValue: 1.0, encoder: encoder, index: GLLFragmentArgumentIndexSpecularTextureScale)
        assignParameterFloat(name: "reflectionAmount", defaultValue: 0.0, encoder: encoder, index: GLLFragmentArgumentIndexReflectionAmount)
    }
    
    var isBlended: Bool {
        guard let shader = itemMesh.shader else {
            return false;
        }
        
        return shader.alphaBlending
    }
    
    /**
     * Updates the textures. Returns which ones could not be loaded and the associated error.
     */
    func updateTextures() -> [String: Error] {
        var failures: [String: Error] = [:]
        
        guard let shader = itemMesh.shader else {
            return failures
        }
        
        texturesForResourceIds.removeAll()
        for identifier in shader.textureUniforms {
            do {
                let texture = try loadTexture(identifier: identifier)
                texturesForResourceIds[textureIndex(for: identifier)] = texture.texture
            } catch {
                failures[identifier] = error
                
                // Load default
                let texture = try! drawer.resourceManager.texture(url: itemMesh.mesh.model!.parameters.defaultValue(forTexture: identifier))
                texturesForResourceIds[textureIndex(for: identifier)] = texture.texture
            }
        }
        
        needsTextureUpdate = false
        updateArgumentBuffer()
        return failures
    }
        
    private func updatePipelineState() {
        guard let shader = itemMesh.shader else {
            pipelineStateInformation = nil
            return;
            
        }
        
        var texCoordAssignments: [Int: Int] = [:]
        for identifier in shader.textureUniforms {
            let index = textureIndex(for: identifier)
            if let assignment = itemMesh.texture(withIdentifier: identifier) {
                if (assignment.texCoordSet < 0) {
                    if let texture = itemMesh.mesh.textures[identifier], texture.texCoordSet > 0 {
                        texCoordAssignments[index] = min(texture.texCoordSet, itemMesh.mesh.countOfUVLayers - 1)
                    }
                } else if assignment.texCoordSet >= 1{
                    texCoordAssignments[index] = min(Int(assignment.texCoordSet), itemMesh.mesh.countOfUVLayers - 1)
                }
            }
        }
        
        pipelineStateInformation = try! drawer.resourceManager.pipeline(vertex: meshData.vertexArray.optimizedFormat, shader: shader, numberOfTexCoordSets: itemMesh.mesh.countOfUVLayers, texCoordAssignments: texCoordAssignments)
        
        argumentsEncoder = nil
        updateArgumentBuffer()
    }
    
    var cullMode: MTLCullMode {
        let cullFaceMode = GLLCullFaceMode(rawValue: Int(itemMesh.cullFaceMode))!
        switch cullFaceMode {
        case .counterClockWise:
            return .back
        case .clockWise:
            return .front
        case .none:
            return .none
        @unknown default:
            fatalError()
        }
    }
    
    func render(into commandEncoder: MTLRenderCommandEncoder) {
        guard let pipelineStateInformation = pipelineStateInformation, itemMesh.isVisible else {
            return
        }
        
        if needsTextureUpdate {
            _ = updateTextures()
        }
        
        /// TODO Ugly
        let textures = texturesForResourceIds.values.map { $0 }
        commandEncoder.useResources(textures, usage: .sample)
        
        commandEncoder.setRenderPipelineState(pipelineStateInformation.pipelineState)
        commandEncoder.setFragmentBuffer(fragmentArgumentBuffer, offset: 0, index: Int(GLLFragmentBufferIndexArguments.rawValue))
        commandEncoder.setVertexBuffer(meshData.vertexArray.vertexBuffer, offset: 0, index: 10)
        commandEncoder.setCullMode(cullMode)

        if let elementBuffer = meshData.vertexArray.elementBuffer {
            commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: meshData.elementsOrVerticesCount, indexType: meshData.elementType, indexBuffer: elementBuffer, indexBufferOffset: meshData.indicesStart, instanceCount: 1, baseVertex: meshData.baseVertex, baseInstance: 0)
        } else {
            commandEncoder.drawPrimitives(type: .triangle, vertexStart: meshData.baseVertex, vertexCount: meshData.elementsOrVerticesCount)
        }
    }
}
