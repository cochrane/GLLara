//
//  GLLTexture.swift
//  GLLara
//
//  Created by Torsten Kammer on 04.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal
import CoreGraphics
import UniformTypeIdentifiers
import System

@objc class GLLTexture: NSObject, NSFilePresenter {
    
    private static let informationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    static let changeNotification = "GLL Texture Change Notification"
    
    @objc var width: Int = 0
    @objc var height: Int = 0
    var device: MTLDevice
    var url: URL
    var texture: MTLTexture! = nil
    
    init(url: URL, device: MTLDevice) throws {
        self.url = url
        self.device = device
        
        super.init()
        
        NSFileCoordinator.addFilePresenter(self)
        setupGCDObserving()
        try loadFile()
    }
    
    /**
     * @abstract Load from data (assuming this is part of some other file)
     * @discussion Intended in particular for glTF (binary glTF and data URIs in it),
     * where the file may start sort of randomly, and where updating the texture
     * independent of the model is not possible anyway.
     */
    init(data: Data, sourceURL: URL, device: MTLDevice) throws {
        self.url = sourceURL
        self.device = device
        
        super.init()
        
        NSFileCoordinator.addFilePresenter(self)
        setupGCDObserving()
        try loadData(data: data)
    }
    
    /// We need this to observe low-level changes that don't go through an NSFilePresenter
    private func setupGCDObserving() {
        guard let path = FilePath(url) else {
            return
        }
        guard let filehandle = try? FileDescriptor.open(path, .readOnly, options: [.eventOnly]) else {
            return
        }
        
        let dispatchSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: filehandle.rawValue, eventMask: [.delete, .write, .extend, .attrib, .link, .rename, .revoke], queue: DispatchQueue.main)
        dispatchSource.setEventHandler { [weak self] in
            guard let self else {
                return
            }
            dispatchSource.cancel()
            setupGCDObserving()
            do {
                try loadFile()
            } catch let error as NSError {
                print("Error reloading file \(error)")
            }
        }
        dispatchSource.setCancelHandler { try? filehandle.close() }
        dispatchSource.resume()
    }
    
    private func loadFile() throws {
        let coordinator = NSFileCoordinator(filePresenter: self)
        var coordinationError: NSError? = nil
        var internalError: NSError? = nil
        coordinator.coordinate(readingItemAt: url, options: [.resolvesSymbolicLink], error: &coordinationError) { newUrl in
            do {
                let data = try Data(contentsOf: newUrl)
                try loadData(data: data)
            } catch let error as NSError {
                internalError = error
            }
        }
        if let coordinationError {
            throw coordinationError
        }
        if let internalError {
            throw internalError
        }
    }
    
    private func loadData(data: Data) throws {
        if data.count < 4 {
            throw NSError(domain: "Textures", code: 12, userInfo: [
                NSLocalizedDescriptionKey: String(format: NSLocalizedString("Texture file %@ couldn't be opened because it is too short.", comment: "Data count smaller 4"), url.lastPathComponent)
            ])
        }
        
        if data[0] == Character("D").asciiValue! && data[1] == Character("D").asciiValue! && data[2] == Character("S").asciiValue! && data[3] == Character(" ").asciiValue! {
            try loadDDSTexture(data: data)
        } else {
            try loadCGCompatibleTexture(data: data)
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(GLLTexture.changeNotification), object: self)
        }
    }
    
    func loadDDSTexture(data: Data) throws {
        do {
            let ddsFile = try GLLDDSFile(data: data)
            
            height = ddsFile.height
            width = ddsFile.width
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: ddsFile.hasMipmaps)
            if device.hasUnifiedMemory {
                descriptor.storageMode = .shared
            }
            
            if ddsFile.numMipmaps != 0 {
                if ddsFile.numMipmaps != descriptor.mipmapLevelCount {
                    print("Unexpectedly few mipmaps in \(url)")
                }
                descriptor.mipmapLevelCount = ddsFile.numMipmaps
            } else {
                descriptor.mipmapLevelCount = 1
            }
            
            var expand24BitFormat = false
            switch ddsFile.dataFormat {
            case .dxt1:
                descriptor.pixelFormat = .bc1_rgba
            case .dxt3:
                descriptor.pixelFormat = .bc2_rgba
            case .dxt5:
                descriptor.pixelFormat = .bc3_rgba
            case .bgr8:
                descriptor.pixelFormat = .bgra8Unorm
                expand24BitFormat = true
            case .bgra8:
                descriptor.pixelFormat = .bgra8Unorm
            case .rgba8:
                descriptor.pixelFormat = .rgba8Unorm
                break;
            case .argb4:
                // TODO Does this need swizzling? Probably, right?
                descriptor.pixelFormat = .abgr4Unorm
                descriptor.swizzle = MTLTextureSwizzleChannels(red: .green, green: .red, blue: .alpha, alpha: .blue)
            case .rgb565:
                descriptor.pixelFormat = .b5g6r5Unorm
                break;
            case .argb1555:
                descriptor.pixelFormat = .bgr5A1Unorm
                break;
            case .bgrx8:
                descriptor.pixelFormat = .bgra8Unorm
            default:
                throw NSError(domain:"Textures", code:12, userInfo:[
                    NSLocalizedDescriptionKey : String(format:NSLocalizedString("DDS File %@ couldn't be opened: Pixel format is not supported", comment: "Can't find pixel format"), self.url.lastPathComponent)
                ]);
            }
            
            texture = device.makeTexture(descriptor: descriptor)
            texture.label = self.url.lastPathComponent
            
            for i in 0 ..< descriptor.mipmapLevelCount {
                let levelWidth = max(width >> i, 1)
                let levelHeight = max(height >> i, 1)
                let region = MTLRegionMake2D(0, 0, levelWidth, levelHeight)
                
                guard let data = ddsFile.data(mipmapLevel: i) else {
                    throw NSError(domain:"Textures", code:12, userInfo:[
                        NSLocalizedDescriptionKey : String(format:NSLocalizedString("DDS File %@ couldn't be opened: No data for mipmap level %ld", comment: "Can't find load mipmap level"), self.url.lastPathComponent, i)
                    ]);
                }
                if expand24BitFormat {
                    // Metal does not support 24 bit texture formats, so we need to expand this data manually.
                    // Grr
                    let pixels = levelWidth * levelHeight;
                    var resizedData = Array<UInt8>(repeating: 0, count: pixels * 4)
                    for i in 0 ..< pixels {
                        resizedData[i*4 + 0] = data[i*3 + 0]
                        resizedData[i*4 + 1] = data[i*3 + 1]
                        resizedData[i*4 + 2] = data[i*3 + 2]
                        resizedData[i*4 + 3] = 0xFF
                    }
                    resizedData.withUnsafeBytes { bytes in
                        texture.replace(region: region, mipmapLevel: i, withBytes: bytes.baseAddress!, bytesPerRow: levelWidth * 4)
                    }
                } else {
                    var bytesPerRow = data.count / levelHeight
                    if descriptor.pixelFormat == .bc1_rgba {
                        let blocksPerRow = max(1, levelWidth/4)
                        let blockSize = 8
                        bytesPerRow = blocksPerRow * blockSize
                    } else if descriptor.pixelFormat == .bc2_rgba || descriptor.pixelFormat == .bc3_rgba {
                        let blocksPerRow = max(1, levelWidth/4)
                        let blockSize = 16
                        bytesPerRow = blocksPerRow * blockSize
                    }
                    
                    data.withUnsafeBytes { bytes in
                        texture.replace(region: region, mipmapLevel: i, withBytes: bytes.baseAddress!, bytesPerRow: bytesPerRow)
                    }
                }
            }
            
        } catch let error as NSError {
            // Nicer error-message
            throw NSError(domain: "Textures", code: 12, userInfo: [
                NSLocalizedDescriptionKey: String(format: NSLocalizedString("DDS File %@ couldn't be opened: %@", comment: "DDSOpenData returned NULL"), self.url.lastPathComponent, error.localizedDescription),
                NSLocalizedRecoverySuggestionErrorKey: error.localizedRecoverySuggestion ?? ""
            ])
        }
    }
    
    private func loadCGCompatibleTexture(data: Data) throws {
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let status = CGImageSourceGetStatus(source)
        switch status {
        case .statusUnexpectedEOF:
            throw textureError(description: NSLocalizedString("Texture file %@ could not be loaded due to unexpected file.", comment: "texture status unexpectedEOF"))
        case .statusInvalidData:
            throw textureError(description: NSLocalizedString("Texture file %@ could not be loaded because the data is invalid.", comment: "texture status invalidData"))
        case .statusUnknownType:
            throw textureError(description: NSLocalizedString("Texture file %@ could not be loaded because the type is not supported.", comment: "texture status unknownType"))
        case .statusReadingHeader:
            throw textureError(description: NSLocalizedString("Texture file %@ could not be loaded due to unexpected file.", comment: "texture status unexpectedEOF"))
        case .statusIncomplete:
            throw textureError(description: NSLocalizedString("Texture file %@ could not be loaded due to unexpected file.", comment: "texture status unexpectedEOF"))
        case .statusComplete:
            // All good
            break
        @unknown default:
            throw textureError(description: NSLocalizedString("Texture file %@ could not be loaded due to an unexpected status.", comment: "texture status unknown cgimagesource status"))
        }
        
        let sourceType = CGImageSourceGetType(source)
        if sourceType as? String == UTType.pdf.identifier {
            try loadPdfTexture(data: data)
            return
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: colorSpace, bitmapInfo: CGBitmapInfo(rawValue:  CGImageAlphaInfo.first.rawValue | CGBitmapInfo.byteOrderDefault.rawValue))!
        var buffer = try vImage_Buffer(cgImage: image, format: format)
        height = Int(buffer.height)
        width = Int(buffer.width)
        
        try loadAndFree(unpremultipliedARGB: &buffer)
    }
    
    /// Just for fun
    private func loadPdfTexture(data: Data) throws {
        guard let dataProvider = CGDataProvider(data: data as CFData), let document = CGPDFDocument(dataProvider) else {
            throw textureError(description: NSLocalizedString("PDF Texture file %@ could not be loaded.", comment: "texture status pdf not loaded"))
        }
        
        let numberOfPages = document.numberOfPages
        if numberOfPages == 0 {
            throw textureError(description: NSLocalizedString("PDF Texture file %@ has no pages.", comment: "texture status pdf no pages"))
        }
        
        // PDF pages start at 1
        guard let page = document.page(at: 1) else {
            throw textureError(description: NSLocalizedString("Could not load first page of PDF file %@.", comment: "texture status pdf no pages"))
        }
        
        // Find user unit, if any
        var userUnit: CGPDFReal = 1.0
        if let pageDictionary = page.dictionary {
            if !withUnsafeMutablePointer(to: &userUnit, { bytes in
                CGPDFDictionaryGetNumber(pageDictionary, "UserUnit", bytes)
            }) {
                userUnit = 1.0
            }
        }
        // Unit is userUnit / 72 inch. We want 300 DPI.
        var scale: CGFloat = (userUnit / 72.0) * 300.0;
        
        // Limit size
        let maxSize: CGFloat = 2048
        let boxRect = page.getBoxRect(.cropBox)
        if boxRect.size.width * scale > maxSize {
            scale = maxSize / boxRect.size.width
        }
        if boxRect.size.height * scale > maxSize {
            scale = maxSize / boxRect.size.height
        }
        
        width = Int(boxRect.size.width * scale)
        height = Int(boxRect.size.height * scale)
        
        var buffer = try vImage_Buffer(width: width, height: height, bitsPerPixel: 32)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: buffer.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
        context.scaleBy(x: scale, y: scale)
                context.drawPDFPage(page)
        
        try loadAndFree(premultipliedARGB: &buffer)
    }
    
    private func loadAndFree(premultipliedARGB inputBuffer: inout vImage_Buffer) throws {
        // Unpremultiply the texture data. I wish I could get it unpremultiplied from the start, but CGImage doesn't allow that. Just using premultiplied sounds swell, but it messes up my blending in OpenGL.
        
        // Copy of buffer does not copy allocation (I think)
        var outputBuffer = try vImage_Buffer(width: width, height: height, bitsPerPixel: 32)
        vImageUnpremultiplyData_ARGB8888(&inputBuffer, &outputBuffer, 0)
        inputBuffer.free()
        
        try loadAndFree(unpremultipliedARGB: &outputBuffer)
    }
    
    private var numMipmapLevels: Int {
        let rulingDimension = max(width, height)
        let firstBit = flsl(rulingDimension) // Computes floor(log2(x)). We want ceil(log2(x))
        if (rulingDimension & ~(1 << firstBit)) == 0 {
            return Int(firstBit - 1)
        }
        return Int(firstBit)
    }
    
    private func loadAndFree(unpremultipliedARGB inputBuffer: inout vImage_Buffer) throws {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: true)
        if device.hasUnifiedMemory {
            descriptor.storageMode = .shared
        }
        // Metal does not support any alpha-first formats, and we need ARGB for the other steps to work, so swizzle
        // A -> B
        // R -> G
        // G -> R
        // B -> A
        descriptor.swizzle = MTLTextureSwizzleChannels(red: .green, green: .red, blue: .alpha, alpha: .blue)
        texture = device.makeTexture(descriptor: descriptor)
        texture.label = url.lastPathComponent
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: inputBuffer.data, bytesPerRow: inputBuffer.rowBytes)
        
        // Load mipmaps
        var lastBuffer = inputBuffer
        var tempBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: width * height * 4, alignment: 1024)
        for i in 1 ..< numMipmapLevels {
            var smallerBuffer = try vImage_Buffer(width: max(width >> i, 1), height: max(height >> i, 1), bitsPerPixel: 32)
            let minTempSize = vImageScale_ARGB8888(&lastBuffer, &smallerBuffer, nil, vImage_Flags(kvImageGetTempBufferSize))
            if minTempSize > tempBuffer.count {
                tempBuffer.deallocate()
                tempBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: minTempSize, alignment: 1024)
            }
            
            vImageScale_ARGB8888(&lastBuffer, &smallerBuffer, tempBuffer.baseAddress, vImage_Flags(kvImageEdgeExtend))
            lastBuffer.free()
            
            let region = MTLRegionMake2D(0, 0, Int(smallerBuffer.width), Int(smallerBuffer.height))
            texture.replace(region: region, mipmapLevel: i, withBytes: smallerBuffer.data, bytesPerRow: smallerBuffer.rowBytes)
            
            lastBuffer = smallerBuffer
        }
        tempBuffer.deallocate()
        lastBuffer.free()
    }
    
    private func textureError(description: String, recoverySuggestion: String? = nil) -> NSError {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: String(format: description, url.lastPathComponent)
        ]
        if let recoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
        }
        return NSError(domain: "Textures", code: 13, userInfo: userInfo)
    }
    
    // MARK: - File presenter
    var presentedItemOperationQueue: OperationQueue {
        return GLLTexture.informationQueue
    }
    
    var presentedItemURL: URL? {
        return url
    }
    
    func presentedItemDidMove(to newURL: URL) {
        url = newURL
    }
    
    func presentedItemDidChange() {
        DispatchQueue.main.async {
            do {
                try self.loadFile()
            } catch let error as NSError {
                print("Error with changed file: \(error)")
            }
        }
    }
    
    
}
