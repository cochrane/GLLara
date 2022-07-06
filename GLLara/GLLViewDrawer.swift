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
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(), let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        commandEncoder.setTriangleFillMode(.fill)
        commandEncoder.setFrontFacing(.clockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(sceneDrawer.resourceManager.normalDepthStencilState)
        commandEncoder.setFragmentSamplerState(sceneDrawer.resourceManager.metalSampler, index: 0)
        commandEncoder.setBlendColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        if needsUpdateMatrices {
            updateMatrices()
        }
        if needsUpdateLights {
            updateLights()
        }
        
        commandEncoder.setVertexBuffer(transformBuffer, offset: 0, index: Int(GLLVertexInputIndexViewProjection.rawValue))
        commandEncoder.setVertexBuffer(lightBuffer, offset: 0, index: Int(GLLVertexInputIndexLights.rawValue))
        commandEncoder.setFragmentBuffer(lightBuffer, offset: 0, index: Int(GLLFragmentBufferIndexLights.rawValue))
        
        sceneDrawer.draw(showingSelection: self.view!.showSelection, into: commandEncoder)
        
        commandEncoder.endEncoding()
        let drawable = view.currentDrawable
        commandBuffer.present(drawable!)
        commandBuffer.commit()
    }
}
