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
    @objc init(sceneDrawer: GLLSceneDrawer, camera: GLLCamera, view: GLLView) {
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
        
        assert(directionalLights.count == 3, "Only exactly four lights supported at the moment")
        
        // Transform buffer
        transformBuffer = device.makeBuffer(length: MemoryLayout<mat_float16>.stride, options: .storageModeManaged)!
        transformBuffer.label = "global-transform"
        
        // Other necessary render state. Thanks to Metal, that got cut down a lot.
        view.clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0)
        
        solidFence = device.makeFence()!
        solidFence.label = "Solid drawing done"
        
        initializeDepthBufferFence = device.makeFence()!
        initializeDepthBufferFence.label = "Depth buffer initialize done"
        
        lastBufferDoneFence = device.makeFence()!
        lastBufferDoneFence.label = "Depth pass done"
        
        super.init()
        
        keyValueObservers.append(camera.observe(\.viewProjectionMatrix) { [weak self] _,_ in
            self?.needsUpdateMatrices = true
            self?.needsUpdateLights = true
            self?.view?.needsDisplay = true
        })
        keyValueObservers.append(ambientLight.observe(\.color) { [weak self] _,_ in
            self?.needsUpdateLights = true
            self?.view?.needsDisplay = true
        })
        for light in directionalLights {
            keyValueObservers.append(light.observe(\.uniformBlock) { [weak self] _,_ in
                self?.needsUpdateLights = true
                self?.view?.needsDisplay = true
            })
        }
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)
        
        view.delegate = self
    }
    
    let sceneDrawer: GLLSceneDrawer
    let camera: GLLCamera
    weak var view: GLLView?
    
    private let ambientLight: GLLAmbientLight
    private let directionalLights: [GLLDirectionalLight] // Always three, mutations aren't checked
    private let device = GLLResourceManager.shared().metalDevice!
    private let commandQueue: MTLCommandQueue
    private var transformBuffer: MTLBuffer
    private var lightBuffer: MTLBuffer
    private var needsUpdateMatrices = true
    private var needsUpdateLights = true
    private var keyValueObservers: [NSKeyValueObservation] = []
    
    // Depth peeling
    private var drawPassMultisampleTexture: MTLTexture? = nil
    private var drawPassResolvedTextures: [MTLTexture] = []
    private var drawPassSolidDepthTexture: MTLTexture? = nil
    private var drawPassDepthTextures: [MTLTexture] = []
    
    private var clearDepthBuffer0PassDescriptor: MTLRenderPassDescriptor? = nil
    
    private var solidFence: MTLFence
    private var initializeDepthBufferFence: MTLFence
    private var lastBufferDoneFence: MTLFence
    
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
    
    private func updateMatrices() {
        var viewProjection = self.camera.viewProjectionMatrix
        
        // Set the view projection matrix.
        transformBuffer.contents().copyMemory(from: &viewProjection, byteCount: MemoryLayout<matrix_float4x4>.size)
        transformBuffer.didModifyRange(0 ..< MemoryLayout<matrix_float4x4>.size)
        
        needsUpdateMatrices = false
    }
    
    // MARK: - Image rendering
    // Basic support for render to file
    @objc func writeImage(to url: URL, fileType: UTType, size: CGSize) {
        // TODO Not yet implemented for metal
        let dataSize = Int(size.width) * Int(size.height) * 4;
        var imageData = Data(count: dataSize);
        imageData.withUnsafeMutableBytes { bytes in
            renderImage(size: size, toColorBuffer: bytes)
        }
        
        let dataProvider = CGDataProvider(data: imageData as CFData)!
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let image = CGImage(width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, fileType.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
    }
    
    func renderImage(size: CGSize, toColorBuffer colorData: UnsafeMutableRawBufferPointer) {
        // TODO Not yet implemented in swift and for metal
        
        /*
        // What is the largest tile that can be rendered?
        [self.context makeCurrentContext];
        GLint maxTextureSize, maxRenderbufferSize;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderbufferSize);
        // Divide max size by 2; it seems some GPUs run out of steam otherwise.
        GLint maxSize = MIN(maxTextureSize, maxRenderbufferSize) / 4;
        
        // Prepare framebuffer (without texture; a new one is created for every tile)
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        GLuint depthRenderbuffer;
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        
        // Get old viewport. Oh god, a glGet, how slow and annoying
        GLint oldViewport[4];
        glGetIntegerv(GL_VIEWPORT, oldViewport);
        
        // Prepare textures
        GLuint numTextures = ceil(size.width / maxSize) * ceil(size.height / maxSize);
        GLuint *textureNames = calloc(sizeof(GLuint), numTextures);
        glGenTextures(numTextures, textureNames);
        
        // Pepare background thread. This waits until textures are done, then loads them into colorData.
        __block NSUInteger finishedTextures = 0;
        __block dispatch_semaphore_t texturesReady = dispatch_semaphore_create(0);
        __block dispatch_semaphore_t downloadReady = dispatch_semaphore_create(0);
        
        NSOpenGLContext *backgroundLoadingContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:self.context];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [backgroundLoadingContext makeCurrentContext];
            NSUInteger downloadedTextures = 0;
            while (downloadedTextures < numTextures)
            {
                dispatch_semaphore_wait(texturesReady, DISPATCH_TIME_FOREVER);
                
                GLint row = (GLint) downloadedTextures / (GLint) ceil(size.width / maxSize);
                GLint column = (GLint) downloadedTextures % (GLint) ceil(size.width / maxSize);
                
                glPixelStorei(GL_PACK_ROW_LENGTH, size.width);
                glPixelStorei(GL_PACK_SKIP_ROWS, row * maxSize);
                glPixelStorei(GL_PACK_SKIP_PIXELS, column * maxSize);
                
                glBindTexture(GL_TEXTURE_2D, textureNames[downloadedTextures]);
                glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, colorData);
                
                glDeleteTextures(1, &textureNames[downloadedTextures]);
                
                downloadedTextures += 1;
            }
            dispatch_semaphore_signal(downloadReady);
        });
        
        mat_float16 cameraMatrix = [self.camera viewProjectionMatrixForAspectRatio:size.width / size.height];
        
        // Set up state for rendering
        // We invert drawing here so it comes out right in the file. That makes it necessary to turn cull face around.
        glCullFace(GL_FRONT);
        glDisable(GL_MULTISAMPLE);
        
        // Render
        for (NSUInteger y = 0; y < size.height; y += maxSize)
        {
            for (NSUInteger x = 0; x < size.width; x += maxSize)
            {
                // Setup size
                GLuint width = MIN(size.width - x, maxSize);
                GLuint height = MIN(size.height - y, maxSize);
                glViewport(0, 0, width, height);
                
                glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
                
                // Setup buffers + textures
                glBindTexture(GL_TEXTURE_2D, textureNames[finishedTextures]);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureNames[finishedTextures], 0);
                
                glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
                glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, width, height);
                glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
                
                // Setup matrix. First, flip the y direction because OpenGL textures are not the same way around as CGImages. Then, use ortho to select the part that corresponds to the current tile.
                mat_float16 flipMatrix = (mat_float16) { {1,0,0,0},{0, -1, 0,0}, {0,0,1,0}, {0,0,0,1} };
                mat_float16 combinedMatrix = simd_mul(flipMatrix, cameraMatrix);
                mat_float16 partOfCameraMatrix = simd_orthoMatrix((x/size.width)*2.0-1.0, ((x+width)/size.width)*2.0-1.0, (y/size.height)*2.0-1.0, ((y+height)/size.height)*2.0-1.0, 1, -1);
                combinedMatrix = simd_mul(partOfCameraMatrix, combinedMatrix);
                
                glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
                glBufferData(GL_UNIFORM_BUFFER, sizeof(combinedMatrix), NULL, GL_STREAM_DRAW);
                
                mat_float16 *data = glMapBuffer(GL_UNIFORM_BUFFER, GL_WRITE_ONLY);
                memcpy(data, &combinedMatrix, sizeof(combinedMatrix));
                glUnmapBuffer(GL_UNIFORM_BUFFER);
                
                // Enable blend for entire scene. That way, new alpha are correctly combined with values in the buffer (instead of stupidly overwriting them), giving the rendered image a correct alpha channel.
                glEnable(GL_BLEND);
                
                [self drawShowingSelection:NO resetState:YES];
                
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
                
                glFlush();
                
                // Clean up and inform background thread to start loading.
                finishedTextures += 1;
                dispatch_semaphore_signal(texturesReady);
            }
        }
        
        dispatch_semaphore_wait(downloadReady, DISPATCH_TIME_FOREVER);
        glViewport(oldViewport[0], oldViewport[1], oldViewport[2], oldViewport[3]);
        glDeleteFramebuffers(1, &framebuffer);
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        glCullFace(GL_BACK);
        glEnable(GL_MULTISAMPLE);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
        
        needsUpdateMatrices = YES;
        self.view.needsDisplay = YES;
         */

    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.actualWindowWidth = Float(size.width)
        camera.actualWindowHeight = Float(size.height)
        
        // Recreate textures
        let multisampleTextureDescriptor = MTLTextureDescriptor()
        multisampleTextureDescriptor.width = Int(size.width)
        multisampleTextureDescriptor.height = Int(size.height)
        multisampleTextureDescriptor.allowGPUOptimizedContents = true
        multisampleTextureDescriptor.textureType = .type2DMultisample
        multisampleTextureDescriptor.pixelFormat = .bgra8Unorm
        multisampleTextureDescriptor.storageMode = .private
        multisampleTextureDescriptor.sampleCount = 4 // TODO Make dependent on user settings
        multisampleTextureDescriptor.usage = [ .renderTarget ]
        
        drawPassMultisampleTexture = device.makeTexture(descriptor: multisampleTextureDescriptor)!
        drawPassMultisampleTexture!.label = "multisample"
        
        drawPassResolvedTextures.removeAll()
        let depthPeelLayerCount = 8
        for i in 0..<depthPeelLayerCount {
            let resolvedTextureDescriptor = MTLTextureDescriptor()
            resolvedTextureDescriptor.width = Int(size.width)
            resolvedTextureDescriptor.height = Int(size.height)
            resolvedTextureDescriptor.allowGPUOptimizedContents = true
            resolvedTextureDescriptor.textureType = .type2D
            resolvedTextureDescriptor.pixelFormat = .bgra8Unorm
            resolvedTextureDescriptor.storageMode = .private
            resolvedTextureDescriptor.usage = [ .shaderRead, .renderTarget ]
            
            let texture = device.makeTexture(descriptor: resolvedTextureDescriptor)!
            texture.label = "color-res-\(i)"
            drawPassResolvedTextures.append(texture)
        }
        
        let depthTextureDescriptor = MTLTextureDescriptor()
        depthTextureDescriptor.width = Int(size.width)
        depthTextureDescriptor.height = Int(size.height)
        depthTextureDescriptor.allowGPUOptimizedContents = true
        depthTextureDescriptor.textureType = .type2DMultisample
        depthTextureDescriptor.pixelFormat = .depth32Float
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.sampleCount = 4 // TODO Make dependent on user settings
        depthTextureDescriptor.usage = [ .shaderRead, .renderTarget ]
        
        drawPassSolidDepthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
        drawPassSolidDepthTexture!.label = "depth-solid"
        
        drawPassDepthTextures.removeAll()
        for i in 0..<2 {
            let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
            depthTexture.label = "depth-\(i)"
            drawPassDepthTextures.append(depthTexture)
        }
        
        clearDepthBuffer0PassDescriptor = MTLRenderPassDescriptor()
        clearDepthBuffer0PassDescriptor!.depthAttachment.texture = drawPassDepthTextures[0]
        clearDepthBuffer0PassDescriptor!.depthAttachment.loadAction = .clear
        clearDepthBuffer0PassDescriptor!.depthAttachment.storeAction = .store
        clearDepthBuffer0PassDescriptor!.depthAttachment.clearDepth = 0.0
        clearDepthBuffer0PassDescriptor!.renderTargetWidth = drawPassSolidDepthTexture!.width
        clearDepthBuffer0PassDescriptor!.renderTargetHeight = drawPassSolidDepthTexture!.height
    }
    
    func draw(in view: MTKView) {
        guard let viewRenderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        if needsUpdateMatrices {
            updateMatrices()
        }
        if needsUpdateLights {
            updateLights()
        }
        
        // Step 1: Create render pass that renders everything solid, to the multisample texture, with depth buffer 0 as normal depth buffer, resolving to resolved texture 0.
        //TODO
        let solidRenderPassDescriptor = MTLRenderPassDescriptor()
        solidRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0)
        solidRenderPassDescriptor.colorAttachments[0].texture = drawPassMultisampleTexture!
        solidRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        solidRenderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        solidRenderPassDescriptor.colorAttachments[0].resolveTexture = drawPassResolvedTextures[0]
        solidRenderPassDescriptor.depthAttachment.texture = drawPassSolidDepthTexture!
        solidRenderPassDescriptor.depthAttachment.loadAction = .clear
        solidRenderPassDescriptor.depthAttachment.storeAction = .store
        solidRenderPassDescriptor.renderTargetWidth = drawPassSolidDepthTexture!.width
        solidRenderPassDescriptor.renderTargetHeight = drawPassSolidDepthTexture!.height
        
        let solidPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: solidRenderPassDescriptor)!
        solidPassEncoder.label = "Draw solids"
        solidPassEncoder.setCullMode(.back)
        solidPassEncoder.setDepthStencilState(sceneDrawer.resourceManager.normalDepthStencilState)
        solidPassEncoder.setFragmentSamplerState(sceneDrawer.resourceManager.metalSampler, index: 0)
        solidPassEncoder.setVertexBuffer(transformBuffer, offset: 0, index: Int(GLLVertexInputIndexViewProjection.rawValue))
        solidPassEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
        solidPassEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
        
        sceneDrawer.draw(into: solidPassEncoder, blended: false)
        
        solidPassEncoder.updateFence(solidFence, after: [.fragment])
        solidPassEncoder.endEncoding()

        // Step 2: For every further resolved texture we have:
        // - Use previous depth buffer as peel front buffer (only things behind it get drawn)
        // - Use other depth buffer as normal depth buffer, but initialized to depth buffer from solid
        // - Draw alpha, into multisample texture, resolving to resolved texture i
        
        let clearDepthBuffer0Pass = commandBuffer.makeRenderCommandEncoder(descriptor: clearDepthBuffer0PassDescriptor!)!
        clearDepthBuffer0Pass.label = "Clear Depth Buffer 0"
        clearDepthBuffer0Pass.updateFence(lastBufferDoneFence, after: [.fragment])
        clearDepthBuffer0Pass.endEncoding()
        
        let depthPeelPassDescriptor = MTLRenderPassDescriptor()
        depthPeelPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        depthPeelPassDescriptor.colorAttachments[0].texture = drawPassMultisampleTexture!
        depthPeelPassDescriptor.colorAttachments[0].loadAction = .clear
        depthPeelPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        depthPeelPassDescriptor.depthAttachment.loadAction = .load
        depthPeelPassDescriptor.depthAttachment.storeAction = .store
        depthPeelPassDescriptor.renderTargetWidth = drawPassSolidDepthTexture!.width
        depthPeelPassDescriptor.renderTargetHeight = drawPassSolidDepthTexture!.height

        
        var lastWrittenDepthBuffer = 0
        for i in 1 ..< drawPassResolvedTextures.count {
            let backDepthBuffer = 1 - lastWrittenDepthBuffer
            let isLast = i + 1 == drawPassResolvedTextures.count
            
            let initializeDepthBufferEncoder = commandBuffer.makeBlitCommandEncoder()!
            initializeDepthBufferEncoder.label = "Initialize Depth Buffer \(i)"
            initializeDepthBufferEncoder.waitForFence(lastBufferDoneFence)
            if i == 1 {
                initializeDepthBufferEncoder.waitForFence(solidFence)
            }
            initializeDepthBufferEncoder.copy(from: drawPassSolidDepthTexture!, to: drawPassDepthTextures[backDepthBuffer])
            initializeDepthBufferEncoder.updateFence(initializeDepthBufferFence)
            initializeDepthBufferEncoder.endEncoding()
            
            depthPeelPassDescriptor.colorAttachments[0].resolveTexture = drawPassResolvedTextures[i]
            depthPeelPassDescriptor.depthAttachment.texture = drawPassDepthTextures[backDepthBuffer]
            if isLast {
                depthPeelPassDescriptor.depthAttachment.storeAction = .dontCare
            }

            let depthPeelPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthPeelPassDescriptor)!
            depthPeelPassEncoder.label = "Depth Peel Layer \(i)"
            depthPeelPassEncoder.waitForFence(initializeDepthBufferFence, before: [ .fragment ])
            depthPeelPassEncoder.setCullMode(.back)
            depthPeelPassEncoder.setDepthStencilState(sceneDrawer.resourceManager.normalDepthStencilState)
            depthPeelPassEncoder.setFragmentSamplerState(sceneDrawer.resourceManager.metalSampler, index: 0)
            depthPeelPassEncoder.setVertexBuffer(transformBuffer, offset: 0, index: Int(GLLVertexInputIndexViewProjection.rawValue))
            depthPeelPassEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
            depthPeelPassEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
            
            depthPeelPassEncoder.setFragmentTexture(drawPassDepthTextures[lastWrittenDepthBuffer], index: Int(GLLFragmentArgumentIndexTextureDepthPeelFront.rawValue))
            
            sceneDrawer.draw(into: depthPeelPassEncoder, blended: true)
            
            // TODO We should combine the buffer we were reading from into the back buffer/next front buffer here, storing the max of each pixel
           /* if !isLast {
                depthPeelPassEncoder.setRenderPipelineState(sceneDrawer.resourceManager.copyDepthPipelineState)
                depthPeelPassEncoder.setDepthStencilState(sceneDrawer.resourceManager.depthStencilStateForCopy)
                depthPeelPassEncoder.setVertexBuffer(sceneDrawer.resourceManager.squareVertexArray, offset: 0, index: 0)
                depthPeelPassEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }*/
            
            depthPeelPassEncoder.updateFence(lastBufferDoneFence, after: [ .fragment ])
            depthPeelPassEncoder.endEncoding()
            
            lastWrittenDepthBuffer = backDepthBuffer
        }
        
        // Step 3: Using the view render pass descriptor, render all resolved textures on top of each other with blending.
        let combineCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewRenderPassDescriptor)!
        
        combineCommandEncoder.label = "Final combine"
        combineCommandEncoder.waitForFence(lastBufferDoneFence, before: [.fragment])
        combineCommandEncoder.setRenderPipelineState(sceneDrawer.resourceManager.squarePipelineState)
        combineCommandEncoder.setVertexBuffer(sceneDrawer.resourceManager.squareVertexArray, offset: 0, index: 0)
        
        // Order: 0, n-1, n-2, ..., 1
        combineCommandEncoder.setFragmentTexture(drawPassResolvedTextures[0], index: 0)
        combineCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        for i in 1 ..< drawPassResolvedTextures.count {
            combineCommandEncoder.setFragmentTexture(drawPassResolvedTextures[drawPassResolvedTextures.count - i], index: 0)
            combineCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        // Step 3.5: If present, draw the skeleton view on top of all that.
        if self.view?.showSelection ?? false {
            combineCommandEncoder.setVertexBuffer(transformBuffer, offset: 0, index: Int(GLLVertexInputIndexViewProjection.rawValue))
            combineCommandEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
            combineCommandEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
            
            sceneDrawer.drawSelection(int: combineCommandEncoder)
        }
        
        combineCommandEncoder.endEncoding()
        let drawable = view.currentDrawable
        commandBuffer.present(drawable!)
        commandBuffer.commit()
    }
}
