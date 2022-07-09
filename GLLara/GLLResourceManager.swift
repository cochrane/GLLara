//
//  GLLResourceManager.swift
//  GLLara
//
//  Created by Torsten Kammer on 07.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal
import AppKit

/*
 * Stores all resources for the program.
 */
@objc class GLLResourceManager: NSObject {
    
    @objc static var shared: GLLResourceManager = GLLResourceManager()
    
    override init() {
        metalDevice = MTLCreateSystemDefaultDevice()!
        library = metalDevice.makeDefaultLibrary()!
        pixelFormat = .bgra8Unorm
        depthPixelFormat = .depth32Float
        
        let normalDepthStencilDescriptor = MTLDepthStencilDescriptor()
        normalDepthStencilDescriptor.depthCompareFunction = .less
        normalDepthStencilDescriptor.isDepthWriteEnabled = true
        normalDepthStencilDescriptor.label = "normal depth mode"
        normalDepthStencilState = metalDevice.makeDepthStencilState(descriptor: normalDepthStencilDescriptor)!
        
        let copyDepthDescriptor = MTLDepthStencilDescriptor()
        copyDepthDescriptor.depthCompareFunction = .greaterEqual
        copyDepthDescriptor.isDepthWriteEnabled = true;
        copyDepthDescriptor.label = "depth copy mode"
        depthStencilStateForCopy = metalDevice.makeDepthStencilState(descriptor: copyDepthDescriptor)!
    
        // Can be rendered as triangle stripe
        let squareCoords: [Float32] = [
            -1.0, -1.0,
            1.0, -1.0,
            -1.0, 1.0,
            1.0, 1.0
        ]
        squareVertexArray = metalDevice.makeBuffer(bytes: squareCoords, length: MemoryLayout<Float32>.stride * squareCoords.count, options: .storageModeManaged)!
        squareVertexArray.label = "square-vertex"
        
        let squarePipelineDescriptor = MTLRenderPipelineDescriptor()
        squarePipelineDescriptor.vertexFunction = library.makeFunction(name: "squareVertex")!
        squarePipelineDescriptor.fragmentFunction = library.makeFunction(name: "squareFragment")!
        squarePipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        squarePipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        squarePipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        squarePipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        squarePipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        squarePipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        squarePipelineDescriptor.label = "square"
        squarePipelineState = try! metalDevice.makeRenderPipelineState(descriptor: squarePipelineDescriptor)
        
        let copyDepthPipelineDescriptor = MTLRenderPipelineDescriptor()
        copyDepthPipelineDescriptor.vertexFunction = library.makeFunction(name: "copyDepthVertex")!
        copyDepthPipelineDescriptor.fragmentFunction = library.makeFunction(name: "copyDepthFragment")!
        copyDepthPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        copyDepthPipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        copyDepthPipelineDescriptor.label = "copyDepth"
        copyDepthPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: copyDepthPipelineDescriptor)
        
        let checkDepthPipelineDescriptor = MTLRenderPipelineDescriptor()
        checkDepthPipelineDescriptor.vertexFunction = library.makeFunction(name: "depthBufferCheckVertex")!
        checkDepthPipelineDescriptor.fragmentFunction = library.makeFunction(name: "depthBufferCheckFragment")!
        checkDepthPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        checkDepthPipelineDescriptor.label = "checkDepth"
        depthBufferCheckState = try! metalDevice.makeRenderPipelineState(descriptor: checkDepthPipelineDescriptor)
        
        super.init()
        
        NSUserDefaultsController.shared.addObserver(self, forKeyPath: ("values." + GLLPrefAnisotropyAmount), context: nil)
        NSUserDefaultsController.shared.addObserver(self, forKeyPath: ("values." + GLLPrefUseAnisotropy), context: nil)
        
        recreateSampler()
    }
    
    // Shared programs and buffers that everyone needs sometime
    @objc let maxAnisotropyLevel = 16
    let metalDevice: MTLDevice
    
    let squareVertexArray: MTLBuffer
    let squarePipelineState: MTLRenderPipelineState
    let copyDepthPipelineState: MTLRenderPipelineState
    let depthBufferCheckState: MTLRenderPipelineState // Only used for debugging
    
    let library: MTLLibrary
    let pixelFormat: MTLPixelFormat
    let depthPixelFormat: MTLPixelFormat
    let normalDepthStencilState: MTLDepthStencilState
    let depthStencilStateForCopy: MTLDepthStencilState
    
    // Can and will change if user settings change
    var metalSampler: MTLSamplerState! = nil
    
    func drawData(model: GLLModel) throws -> GLLModelDrawData {
        return value(key: model.baseURL, from: &models) {
            return GLLModelDrawData(model: model, resourceManager: self)
        }
    }
    
    @objc func texture(url: URL) throws -> GLLTexture {
        return try value(key: url, from: &textures) {
            var effectiveUrl = url
            do {
                // TODO shouldn't we use this data somewhere? Maybe? Why are we reading this twice?
                _ = try Data(contentsOf: url)
            } catch  {
                // Second attempt: Maybe there is a default version of that in the bundle.
                // If not, then keep error from first read.
                let originalError = error
                let bundleUrl = Bundle.main.url(forResource: url.lastPathComponent, withExtension: nil)
                guard let bundleUrl = bundleUrl else {
                    throw originalError
                }
                effectiveUrl = bundleUrl
            }
            return try GLLTexture(url: effectiveUrl, device: metalDevice)
        }
    }
    
    func pipeline(vertex: GLLVertexAttribAccessorSet, shader: GLLShaderData, numberOfTexCoordSets: Int, texCoordAssignments: [Int:Int]) throws -> GLLPipelineStateInformation {
        // TODO Does this work?
        let key: [String : AnyHashable] = [
            "shader": shader,
            "vertexDescriptor": vertex.vertexDescriptor,
            "numTexCoords": numberOfTexCoordSets,
            "assignments": texCoordAssignments
        ]
        
        return try value(key: key, from: &pipelines) {
            let vertexFunction = try function(name: shader.vertexName!, shader: shader, numberOfTexCoordSets: numberOfTexCoordSets, texCoordAssignments: texCoordAssignments)
            let fragmentFunction = try function(name: shader.fragmentName!, shader: shader, numberOfTexCoordSets: numberOfTexCoordSets, texCoordAssignments: texCoordAssignments)
            
            let descriptor = MTLRenderPipelineDescriptor()
            
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            descriptor.colorAttachments[0].isBlendingEnabled = false
            descriptor.depthAttachmentPixelFormat = depthPixelFormat
            descriptor.vertexDescriptor = vertex.vertexDescriptor
            
            let pipelineState = try metalDevice.makeRenderPipelineState(descriptor: descriptor)
            return GLLPipelineStateInformation(pipelineState: pipelineState, vertexProgram: vertexFunction, fragmentProgram: fragmentFunction)
        }
    }

    // Specifically used for testing
    func clearInternalCaches() {
        textures.removeAll()
        models.removeAll()
        pipelines.removeAll()
        functions.removeAll()
    }
    
    private var textures: [URL: GLLTexture] = [:]
    private var models: [URL: GLLModelDrawData] = [:]
    private var pipelines: [AnyHashable: GLLPipelineStateInformation] = [:]
    private var functions: [AnyHashable: MTLFunction] = [:]
    
    private func function(name: String, shader: GLLShaderData, numberOfTexCoordSets: Int, texCoordAssignments: [Int:Int]) throws -> MTLFunction {
        // TODO does this work?
        let key: [String : AnyHashable] = [
            "name": name,
            "shader": shader,
            "numTexCoords": numberOfTexCoordSets,
            "assignments": texCoordAssignments
        ]
        
        return try value(key: key, from: &functions) {
            let constantValues = MTLFunctionConstantValues()
            
            // Assign bools for active things
            var valuesArray: [Bool] = Array(repeating: false, count: GLLFunctionConstant.boolMax.rawValue)
            let setParameters = shader.activeBoolConstants
            for i in 0..<valuesArray.count {
                if setParameters.contains(i) {
                    valuesArray[i] = true
                }
            }
            constantValues.setConstantValues(valuesArray, type: .bool, range: 0 ..< valuesArray.count)
            
            // Assign value for tex coord
            var numTexCoords32 = Int32(numberOfTexCoordSets)
            constantValues.setConstantValue(&numTexCoords32, type: .int, index: GLLFunctionConstant.numberOfTexCoordSets.rawValue)
            
            // Assign values for tex coord assignments
            var indexValuesArray = Array.init(repeating: Int32(0), count: Int(GLLFragmentArgumentIndexTextureMax.rawValue))
            for i in 0..<indexValuesArray.count {
                if let assigned = texCoordAssignments[i] {
                    indexValuesArray[i] = Int32(assigned)
                }
            }
            constantValues.setConstantValues(indexValuesArray, type: .int, range: 100 ..< 100 + indexValuesArray.count)
            
            // Set number of active lights - TODO adjust to what it should really be
            var lights = Int32(3)
            constantValues.setConstantValue(&lights, type: .int, index: GLLFunctionConstant.numberOfUsedLights.rawValue)
            
            var depthPeelActive: Bool = shader.alphaBlending
            constantValues.setConstantValue(&depthPeelActive, type: .bool, index: GLLFunctionConstant.hasDepthPeelFrontBuffer.rawValue)
            
            return try library.makeFunction(name: name, constantValues: constantValues)
        }
    }
    
    private func recreateSampler() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.rAddressMode = .repeat
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.supportArgumentBuffers = true
        samplerDescriptor.label = "default"
        
        let useAnisotropy = UserDefaults.standard.bool(forKey: GLLPrefUseAnisotropy)
        let anisotropyAmount = UserDefaults.standard.integer(forKey: GLLPrefAnisotropyAmount)
        samplerDescriptor.maxAnisotropy = useAnisotropy ? anisotropyAmount : 0
        
        metalSampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    private func value<K, V>(key: K, from dictionary: inout [K: V], ifNotFound: () throws -> V) rethrows -> V {
        if let existing = dictionary[key] {
            return existing
        }
        
        let newItem = try ifNotFound()
        dictionary[key] = newItem
        return newItem
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is NSUserDefaultsController.Type {
            recreateSampler()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
