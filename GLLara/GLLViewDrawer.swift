//
//  GLLViewDrawer.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import MetalKit
import UniformTypeIdentifiers

@objc class GLLViewDrawer: NSObject, MTKViewDelegate {
    init(sceneDrawer: GLLSceneDrawer, camera: GLLCamera, view: GLLView) {
        self.sceneDrawer = sceneDrawer
        self.camera = camera
        self.view = view
        
        commandQueue = device.makeCommandQueue()!
        
        // Prepare light buffer.
        lightBuffer = device.makeBuffer(length: MemoryLayout<GLLLightsBuffer>.size, options: .storageModeManaged)!
        lightBuffer.label = "global-lights"
        
        // Load existing lights
        let ambientRequest = NSFetchRequest<GLLAmbientLight>()
        ambientRequest.entity = NSEntityDescription.entity(forEntityName: "GLLAmbientLight", in: sceneDrawer.managedObjectContext!)
        ambientLight = try! sceneDrawer.managedObjectContext!.fetch(ambientRequest)[0];
        
        let directionalLightRequest = NSFetchRequest<GLLDirectionalLight>()
        directionalLightRequest.entity = NSEntityDescription.entity(forEntityName: "GLLDirectionalLight", in: sceneDrawer.managedObjectContext!)
        directionalLightRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        directionalLights = try! sceneDrawer.managedObjectContext!.fetch(directionalLightRequest)
        
        // Other necessary render state. Thanks to Metal, that got cut down a lot.
        view.clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0)
        
        solidFence = device.makeFence()!
        solidFence.label = "Solid drawing done"
        
        initializeDepthBufferFence = device.makeFence()!
        initializeDepthBufferFence.label = "Depth buffer initialize done"
        
        lastBufferDoneFence = device.makeFence()!
        lastBufferDoneFence.label = "Depth pass done"
        
        let size = view.drawableSize
        camera.actualWindowWidth = Float(size.width)
        camera.actualWindowHeight = Float(size.height)
        surface = Surface(width: Int(size.width), height: Int(size.height), device: device)
        
        super.init()
        
        keyValueObservers.append(camera.observe(\.viewProjectionMatrix) { [weak self] _,_ in
            self?.needsUpdateLights = true
            self?.view?.unpause()
        })
        keyValueObservers.append(ambientLight.observe(\.color) { [weak self] _,_ in
            self?.needsUpdateLights = true
            self?.view?.unpause()
        })
        for light in directionalLights {
            keyValueObservers.append(light.observe(\.uniformBlock) { [weak self] _,_ in
                self?.needsUpdateLights = true
                self?.view?.unpause()
            })
        }
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.updateScaleFactor()
        })
        updateScaleFactor()
        
        view.delegate = self
        
        assert(directionalLights.count == 3, "Only exactly four lights supported at the moment")
    }
    
    let sceneDrawer: GLLSceneDrawer
    let camera: GLLCamera
    weak var view: GLLView?
    
    private let ambientLight: GLLAmbientLight
    private let directionalLights: [GLLDirectionalLight] // Always three, mutations aren't checked
    private let device = GLLResourceManager.shared.metalDevice
    private let commandQueue: MTLCommandQueue
    private var lightBuffer: MTLBuffer
    private var needsUpdateLights = true
    private var keyValueObservers: [NSKeyValueObservation] = []
    private var notificationObservers: [NSObjectProtocol] = []
    
    private var internalBufferScaleFactor = 1.0
    private func updateScaleFactor() {
        let newScaleFactor: Double
        if UserDefaults.standard.bool(forKey: GLLPrefUseMSAA) {
            newScaleFactor = 2.0
        } else {
            newScaleFactor = 1.0
        }
        if newScaleFactor != internalBufferScaleFactor {
            internalBufferScaleFactor = newScaleFactor
            // Recreate textures
            if let view = view {
                let size = view.drawableSize
                surface = Surface(width: Int(size.width * internalBufferScaleFactor), height: Int(size.height * internalBufferScaleFactor), device: device)
            }
        }
    }
    
    // Depth peeling
    private struct Surface {
        var colorTextures: [MTLTexture] = []
        var solidDepthTexture: MTLTexture
        var peelDepthTextures: [MTLTexture] = []
        
        var clearDepthBuffer0PassDescriptor: MTLRenderPassDescriptor
        var solidRenderPassDescriptor: MTLRenderPassDescriptor
        
        let width: Int
        let height: Int
        
        init(width: Int, height: Int, device: MTLDevice) {
            self.width = width
            self.height = height
            
            colorTextures.removeAll()
            let depthPeelLayerCount = 8
            for i in 0..<depthPeelLayerCount {
                let resolvedTextureDescriptor = MTLTextureDescriptor()
                resolvedTextureDescriptor.width = width
                resolvedTextureDescriptor.height = height
                resolvedTextureDescriptor.allowGPUOptimizedContents = true
                resolvedTextureDescriptor.textureType = .type2D
                resolvedTextureDescriptor.pixelFormat = .bgra8Unorm
                resolvedTextureDescriptor.storageMode = .private
                resolvedTextureDescriptor.usage = [ .shaderRead, .renderTarget ]
                
                let texture = device.makeTexture(descriptor: resolvedTextureDescriptor)!
                texture.label = "color-res-\(i)"
                colorTextures.append(texture)
            }
            
            let depthTextureDescriptor = MTLTextureDescriptor()
            depthTextureDescriptor.width = width
            depthTextureDescriptor.height = height
            depthTextureDescriptor.allowGPUOptimizedContents = true
            depthTextureDescriptor.textureType = .type2DMultisample
            depthTextureDescriptor.pixelFormat = .depth32Float
            depthTextureDescriptor.storageMode = .private
            depthTextureDescriptor.textureType = .type2D
            depthTextureDescriptor.usage = [ .shaderRead, .renderTarget ]
            
            solidDepthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
            solidDepthTexture.label = "depth-solid"
            
            peelDepthTextures.removeAll()
            for i in 0..<2 {
                let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
                depthTexture.label = "depth-\(i)"
                peelDepthTextures.append(depthTexture)
            }
            
            clearDepthBuffer0PassDescriptor = MTLRenderPassDescriptor()
            clearDepthBuffer0PassDescriptor.depthAttachment.texture = peelDepthTextures[0]
            clearDepthBuffer0PassDescriptor.depthAttachment.loadAction = .clear
            clearDepthBuffer0PassDescriptor.depthAttachment.storeAction = .store
            clearDepthBuffer0PassDescriptor.depthAttachment.clearDepth = 0.0
            clearDepthBuffer0PassDescriptor.renderTargetWidth = solidDepthTexture.width
            clearDepthBuffer0PassDescriptor.renderTargetHeight = solidDepthTexture.height

            solidRenderPassDescriptor = MTLRenderPassDescriptor()
            solidRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
            solidRenderPassDescriptor.colorAttachments[0].texture = colorTextures[0]
            solidRenderPassDescriptor.colorAttachments[0].loadAction = .clear
            solidRenderPassDescriptor.colorAttachments[0].storeAction = .store
            solidRenderPassDescriptor.depthAttachment.texture = solidDepthTexture
            solidRenderPassDescriptor.depthAttachment.loadAction = .clear
            solidRenderPassDescriptor.depthAttachment.storeAction = .store
            solidRenderPassDescriptor.renderTargetWidth = solidDepthTexture.width
            solidRenderPassDescriptor.renderTargetHeight = solidDepthTexture.height
        }
    }
    private var surface: Surface
    
    private var solidFence: MTLFence
    private var initializeDepthBufferFence: MTLFence
    private var lastBufferDoneFence: MTLFence
    
    private var useMultisample = false
    
    private func updateLights() {
        var lightData = GLLLightsBuffer()
        // Camera position
        lightData.cameraPosition = camera.cameraWorldPosition
        
        // Ambient
        lightData.ambientColor = ambientLight.color.rgbaComponents128Bit
        
        // Diffuse + Specular
        lightData.lights.0 = directionalLights[0].uniformBlock
        lightData.lights.1 = directionalLights[1].uniformBlock
        lightData.lights.2 = directionalLights[2].uniformBlock
        
        lightBuffer.contents().copyMemory(from: &lightData, byteCount: MemoryLayout<GLLLightsBuffer>.size)
        lightBuffer.didModifyRange(0 ..< MemoryLayout<GLLLightsBuffer>.size)
        
        needsUpdateLights = false
    }
    
    // MARK: - Image rendering
    // Basic support for render to file
    @objc func writeImage(to url: URL, fileType: UTType, size: CGSize, transparentBackground: Bool) throws {
        // TODO Not yet implemented for metal
        let dataSize = Int(size.width) * Int(size.height) * 4;
        var imageData = Data(count: dataSize);
        imageData.withUnsafeMutableBytes { bytes in
            renderImage(size: size, toColorBuffer: bytes, clearColor: transparentBackground ? MTLClearColorMake(0.0, 0.0, 0.0, 0.0) : MTLClearColorMake(0.2, 0.2, 0.2, 1.0))
        }
        
        let dataProvider = CGDataProvider(data: imageData as CFData)!
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let image = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue + CGImageByteOrderInfo.order32Little.rawValue), provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        
        guard let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, fileType.identifier as CFString, 1, nil) else {
            throw NSError(domain: "exporting", code: 1, userInfo: [
                NSLocalizedFailureErrorKey: NSLocalizedString("Could not open file for writing", comment: "Exporting")
            ])
        }
    
        CGImageDestinationAddImage(imageDestination, image, nil)
        guard CGImageDestinationFinalize(imageDestination) else {
            throw NSError(domain: "exporting", code: 1, userInfo: [
                NSLocalizedFailureErrorKey: NSLocalizedString("Could not finalize image file", comment: "Exporting")
            ])
        }
    }
    
    func renderImage(size: CGSize, toColorBuffer colorData: UnsafeMutableRawBufferPointer, clearColor: MTLClearColor) {
        // TODO Not yet implemented in swift and for metal
        
        let surface = Surface(width: Int(size.width), height: Int(size.height), device: GLLResourceManager.shared.metalDevice)
        let queue = device.makeCommandQueue()!
        queue.label = "Write to file queue"
        let commandBuffer = queue.makeCommandBuffer()!
        commandBuffer.label = "Write to file command buffer"
        
        let outputTextureDescriptor = MTLTextureDescriptor()
        outputTextureDescriptor.width = Int(size.width)
        outputTextureDescriptor.height = Int(size.height)
        outputTextureDescriptor.textureType = .type2D
        outputTextureDescriptor.pixelFormat = .bgra8Unorm
        outputTextureDescriptor.usage = [ .renderTarget ]
        // TODO Settings here to improve readback performance. May not be optimal in all cases.
        outputTextureDescriptor.allowGPUOptimizedContents = false
        outputTextureDescriptor.storageMode = .shared
        
        let outputTexture = device.makeTexture(descriptor: outputTextureDescriptor)!
        
        let outputRenderDescriptor = MTLRenderPassDescriptor()
        outputRenderDescriptor.colorAttachments[0].clearColor = clearColor
        outputRenderDescriptor.colorAttachments[0].loadAction = .clear
        outputRenderDescriptor.colorAttachments[0].storeAction = .store
        outputRenderDescriptor.colorAttachments[0].texture = outputTexture
        outputRenderDescriptor.renderTargetWidth = Int(size.width)
        outputRenderDescriptor.renderTargetHeight = Int(size.height)
        
        draw(commandBuffer: commandBuffer, viewRenderPassDescriptor: outputRenderDescriptor, surface: surface, includeUI: false)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        outputTexture.getBytes(colorData.baseAddress!, bytesPerRow: Int(size.width) * 4, from: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)), mipmapLevel: 0)
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.actualWindowWidth = Float(size.width)
        camera.actualWindowHeight = Float(size.height)
        
        if size.width == 0 || size.height == 0 {
            return;
        }
        
        // Recreate textures
        surface = Surface(width: Int(size.width * internalBufferScaleFactor), height: Int(size.height * internalBufferScaleFactor), device: device)
    }
    
    private func draw(commandBuffer: MTLCommandBuffer, viewRenderPassDescriptor: MTLRenderPassDescriptor, surface: Surface, includeUI: Bool = true) {
        
        var viewProjection = camera.viewProjectionMatrix(forAspectRatio: Float(surface.width) / Float(surface.height))
        
        if needsUpdateLights {
            updateLights()
        }
        
        // Step 1: Render everything solid, with depth buffer 0 as normal depth buffer, to texture 0.
        let solidPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: surface.solidRenderPassDescriptor)!
        solidPassEncoder.label = "Draw solids"
        solidPassEncoder.setCullMode(.back)
        solidPassEncoder.setDepthStencilState(sceneDrawer.resourceManager.normalDepthStencilState)
        solidPassEncoder.setFragmentSamplerState(sceneDrawer.resourceManager.metalSampler, index: 0)
        solidPassEncoder.setVertexBytes(&viewProjection, length: MemoryLayout<float4x4>.size, index: Int(GLLVertexInputIndexViewProjection.rawValue))
        solidPassEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
        solidPassEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
        
        sceneDrawer.draw(into: solidPassEncoder, blended: false)
        
        solidPassEncoder.updateFence(solidFence, after: [.fragment])
        solidPassEncoder.endEncoding()


        // Step 2: For every further resolved texture we have:
        // - Use previous depth buffer as peel front buffer (only things behind it get drawn)
        // - Use other depth buffer as normal depth buffer, but initialized to depth buffer from solid
        // - Draw alpha, into multisample texture, resolving to resolved texture i
        
        let clearDepthBuffer0Pass = commandBuffer.makeRenderCommandEncoder(descriptor: surface.clearDepthBuffer0PassDescriptor)!
        clearDepthBuffer0Pass.label = "Clear Depth Buffer 0"
        clearDepthBuffer0Pass.updateFence(lastBufferDoneFence, after: [.fragment])
        clearDepthBuffer0Pass.endEncoding()
        
        let depthPeelPassDescriptor = MTLRenderPassDescriptor()
        depthPeelPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        depthPeelPassDescriptor.colorAttachments[0].loadAction = .clear
        depthPeelPassDescriptor.colorAttachments[0].storeAction = .store
        depthPeelPassDescriptor.depthAttachment.loadAction = .load
        depthPeelPassDescriptor.depthAttachment.storeAction = .store
        depthPeelPassDescriptor.renderTargetWidth = surface.solidDepthTexture.width
        depthPeelPassDescriptor.renderTargetHeight = surface.solidDepthTexture.height

        
        var lastWrittenDepthBuffer = 0
        for i in 1 ..< surface.colorTextures.count {
            let backDepthBuffer = 1 - lastWrittenDepthBuffer
            let isLast = i + 1 == surface.colorTextures.count
            
            let initializeDepthBufferEncoder = commandBuffer.makeBlitCommandEncoder()!
            initializeDepthBufferEncoder.label = "Initialize Depth Buffer \(i)"
            initializeDepthBufferEncoder.waitForFence(lastBufferDoneFence)
            if i == 1 {
                initializeDepthBufferEncoder.waitForFence(solidFence)
            }
            initializeDepthBufferEncoder.copy(from: surface.solidDepthTexture, to: surface.peelDepthTextures[backDepthBuffer])
            initializeDepthBufferEncoder.updateFence(initializeDepthBufferFence)
            initializeDepthBufferEncoder.endEncoding()
            
            depthPeelPassDescriptor.colorAttachments[0].texture = surface.colorTextures[i]
            depthPeelPassDescriptor.depthAttachment.texture = surface.peelDepthTextures[backDepthBuffer]
            if isLast {
                depthPeelPassDescriptor.depthAttachment.storeAction = .dontCare
            }

            let depthPeelPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthPeelPassDescriptor)!
            depthPeelPassEncoder.label = "Depth Peel Layer \(i)"
            depthPeelPassEncoder.waitForFence(initializeDepthBufferFence, before: [ .vertex ])
            depthPeelPassEncoder.setCullMode(.back)
            depthPeelPassEncoder.setDepthStencilState(sceneDrawer.resourceManager.normalDepthStencilState)
            depthPeelPassEncoder.setFragmentSamplerState(sceneDrawer.resourceManager.metalSampler, index: 0)
            depthPeelPassEncoder.setVertexBytes(&viewProjection, length: MemoryLayout<float4x4>.size, index: Int(GLLVertexInputIndexViewProjection.rawValue))
            depthPeelPassEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
            depthPeelPassEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
            
            depthPeelPassEncoder.setFragmentTexture(surface.peelDepthTextures[lastWrittenDepthBuffer], index: Int(GLLFragmentArgumentIndexTextureDepthPeelFront.rawValue))
            
            sceneDrawer.draw(into: depthPeelPassEncoder, blended: true)
            
            depthPeelPassEncoder.updateFence(lastBufferDoneFence, after: [ .fragment ])
            depthPeelPassEncoder.endEncoding()
            
            lastWrittenDepthBuffer = backDepthBuffer
        }
        
        // Step 3: Using the view render pass descriptor, render all resolved textures on top of each other with blending.
        let combineCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewRenderPassDescriptor)!
        
        combineCommandEncoder.label = "Final combine"
        combineCommandEncoder.waitForFence(lastBufferDoneFence, before: [.vertex])
        combineCommandEncoder.setRenderPipelineState(sceneDrawer.resourceManager.squarePipelineState)
        combineCommandEncoder.setVertexBuffer(sceneDrawer.resourceManager.squareVertexArray, offset: 0, index: 0)
        
        // Order: 0, n-1, n-2, ..., 1
        combineCommandEncoder.setFragmentTexture(surface.colorTextures[0], index: 0)
        combineCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        for i in 1 ..< surface.colorTextures.count {
            combineCommandEncoder.setFragmentTexture(surface.colorTextures[surface.colorTextures.count - i], index: 0)
            combineCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        // Step 3.5: If present, draw the skeleton view on top of all that.
        if includeUI {
            if self.view?.showSelection ?? false {
                combineCommandEncoder.setVertexBytes(&viewProjection, length: MemoryLayout<float4x4>.size, index: Int(GLLVertexInputIndexViewProjection.rawValue))
                combineCommandEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
                combineCommandEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
                
                sceneDrawer.drawSelection(int: combineCommandEncoder)
            }
        }
        
        combineCommandEncoder.endEncoding()
    }
    
    func draw(in view: MTKView) {
        guard let viewRenderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        draw(commandBuffer: commandBuffer, viewRenderPassDescriptor: viewRenderPassDescriptor, surface: surface, includeUI: true)
        
        let drawable = view.currentDrawable
        commandBuffer.present(drawable!)
        commandBuffer.commit()
    }
}
