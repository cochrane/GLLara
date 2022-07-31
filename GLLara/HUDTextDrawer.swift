//
//  HUDTextDrawer.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa
import Metal
import SwiftUI

extension HUDVertex {
    init(x: Float, y: Float, tx: Float, ty: Float) {
        self.init(position: SIMD2<Float>(x: x, y: y),
                  texCoord: SIMD2<Float>(x: tx, y: ty))
    }
}

/**
 A drawer that draws its text on the screen, using a default HUD style. The text is an attributed string to allow for adding SFSymbols, but the overall styling is handled by this drawer internally
 */
struct HUDTextDrawer {
    static let capsuleHeight = 40
    static let capsuleBaseline = 10.0
    static let capsulePaddingLeftRight = 10
    static let capsuleCornerRadius: CGFloat = 5
    
    struct DrawnText {
        let attributedString: NSAttributedString
        let height: Int
        let width: Int
        var data: Data
        
        init(text: NSAttributedString, highlighted: Bool) {
            self.attributedString = text
            
            // Find size
            let frame = text.boundingRect(with: CGSize(width: 2048 - 2*HUDTextDrawer.capsulePaddingLeftRight, height: 2048), options: [ .truncatesLastVisibleLine ], context: nil)
            
            height = max(Int(ceil(frame.height)), HUDTextDrawer.capsuleHeight)
            width = Int(ceil(frame.width)) + 2*HUDTextDrawer.capsulePaddingLeftRight
            data = Data(count: height*width*4)
    
            // Create graphics context
            data.withUnsafeMutableBytes { bytes in
                var mutableBytes = bytes.bindMemory(to: UInt8.self).baseAddress
                let bitmapImageRep = NSBitmapImageRep(bitmapDataPlanes: &mutableBytes,
                                                      pixelsWide: self.width,
                                                      pixelsHigh: self.height,
                                                      bitsPerSample: 8,
                                                      samplesPerPixel: 4,
                                                      hasAlpha: true,
                                                      isPlanar: false,
                                                      colorSpaceName: .calibratedRGB,
                                                      bitmapFormat: [.thirtyTwoBitLittleEndian],
                                                      bytesPerRow: self.width*4,
                                                      bitsPerPixel: 32)!
                
                let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapImageRep)
                let oldContext = NSGraphicsContext.current
                NSGraphicsContext.current = graphicsContext
                
                let path = NSBezierPath(roundedRect: NSMakeRect(0, 0, CGFloat(width), CGFloat(height)),
                                        xRadius: capsuleCornerRadius,
                                        yRadius: capsuleCornerRadius)
                
                if highlighted {
                    let color = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
                    color.set()
                } else {
                    let color = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
                    color.set()
                }
                path.fill()
                
                if !highlighted {
                    let shadow = NSShadow()
                    shadow.shadowOffset = NSSize(width: 0, height: 0)
                    shadow.shadowBlurRadius = 3.0
                    shadow.shadowColor = NSColor.black
                    shadow.set()
                }
                
                text.draw(with: NSMakeRect(CGFloat(capsulePaddingLeftRight), capsuleBaseline, frame.width, frame.height), options: [ .truncatesLastVisibleLine, .usesFontLeading ])
                
                NSGraphicsContext.current = oldContext
            }
        }
    }
    
    class TextureAtlas {
        static let descriptor: MTLTextureDescriptor = {
            let descriptor = MTLTextureDescriptor()
            descriptor.textureType = .type2D
            descriptor.width = 2048
            descriptor.height = 2048
            descriptor.pixelFormat = .bgra8Unorm
            descriptor.storageMode = .shared
            
            return descriptor
        }()
        
        let texture: MTLTexture
        
        struct LineBlock {
            var coveredLines: Int
            var remainingSpace: Int
        }
        
        var occupiedSpace: [LineBlock] = []
        
        init() {
            texture = GLLResourceManager.shared.metalDevice.makeTexture(descriptor: TextureAtlas.descriptor)!
            occupiedSpace = [ LineBlock(coveredLines: texture.height, remainingSpace: texture.width) ]
        }
        
        func tryAdd(_ drawnText: DrawnText) -> CGRect? {
            // Find a block that has enough remaining space
            var beginLine = 0
            for i in 0 ..< occupiedSpace.count {
                let block = occupiedSpace[i]
                if block.remainingSpace >= drawnText.width && block.coveredLines >= drawnText.height {
                    let xBegin = texture.width - block.remainingSpace
                    drawnText.data.withUnsafeBytes { bytes in
                        texture.replace(region: MTLRegionMake2D(xBegin, beginLine, drawnText.width, drawnText.height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: drawnText.width * 4)
                    }
                    
                    // Split block if new height isn't that big
                    if drawnText.height < block.coveredLines {
                        var newBlock = occupiedSpace[i]
                        newBlock.coveredLines -= drawnText.height
                        occupiedSpace.insert(newBlock, at: i+1)
                        occupiedSpace[i].coveredLines = drawnText.height
                    }
                    occupiedSpace[i].remainingSpace -= drawnText.width
                    
                    return CGRect(x: xBegin, y: beginLine, width: drawnText.width, height: drawnText.height)
                } else {
                    beginLine += block.coveredLines
                }
            }
            return nil
        }
    }
    
    private static var textureAtlases: [TextureAtlas] = []
    private static var drawers: [NSAttributedString: HUDTextDrawer] = [:]
    private static var highlightedDrawers: [NSAttributedString: HUDTextDrawer] = [:]
    
    static func drawer(string: String, highlighted: Bool = false) -> HUDTextDrawer {
        return drawer(attributedString: NSAttributedString(string: string), highlighted: highlighted)
    }
    
    static func drawer(systemImage: String, highlighted: Bool = false) -> HUDTextDrawer {
        let image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)!
        let attachment = NSTextAttachment()
        attachment.image = image
        
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        attributedString.addAttributes([
            .baselineOffset: (CGFloat(capsuleHeight) - (image.size.height * 2)) * 0.5
        ], range: NSRange(location: 0, length: attributedString.length))
        
        return drawer(attributedString: attributedString, highlighted: highlighted)
    }
    
    static func drawer(attributedString: NSAttributedString, highlighted: Bool = false) -> HUDTextDrawer {
        // Adjust attributed string to match what we expect
        
        let adjustedString = NSMutableAttributedString(attributedString: attributedString)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: highlighted ? NSColor.black : NSColor.white,
            .font: NSFont.systemFont(ofSize: 25.0, weight: .bold),
        ]
        
        adjustedString.addAttributes(attributes, range: NSRange(location: 0, length: adjustedString.length))
        
        if !highlighted, let drawer = drawers[adjustedString] {
            return drawer
        }
        if highlighted, let drawer = highlightedDrawers[adjustedString] {
            return drawer
        }
        
        // Need to draw and insert into a texture atlas
        let drawnText = DrawnText(text: adjustedString, highlighted: highlighted)
        for textureAtlas in textureAtlases {
            if let rect = textureAtlas.tryAdd(drawnText) {
                let drawer = HUDTextDrawer(atlas: textureAtlas, area: rect)
                if (highlighted) {
                    highlightedDrawers[adjustedString] = drawer
                } else {
                    drawers[adjustedString] = drawer
                }
                return drawer
            }
        }
        // No free space found, gotta open a new texture atlas
        let newAtlas = TextureAtlas()
        textureAtlases.append(newAtlas)
        let rect = newAtlas.tryAdd(drawnText)!
        
        let drawer = HUDTextDrawer(atlas: newAtlas, area: rect)
        if (highlighted) {
            highlightedDrawers[adjustedString] = drawer
        } else {
            drawers[adjustedString] = drawer
        }
        return drawer
    }
    
    private let atlas: TextureAtlas
    private let area: CGRect
    
    init(atlas: TextureAtlas, area: CGRect) {
        self.atlas = atlas
        self.area = area
    }
    
    var size: CGSize {
        return area.size
    }
    
    struct PositionReference {
        /// Relative offset from left. 0 means position refers to left edge, 1 means position refers to right edge
        let offsetX: Double
        /// Relative offset from bottom. 0 means positions refers to bottom edge, 1 means position refers to top edge
        let offsetY: Double
        
        static var bottomLeft = PositionReference(offsetX: 0.0, offsetY: 0.0)
        static var bottomCenter = PositionReference(offsetX: 0.5, offsetY: 0.0)
        static var bottomRight = PositionReference(offsetX: 1.0, offsetY: 0.0)
        
        static var topLeft = PositionReference(offsetX: 0.0, offsetY: 1.0)
        static var topCenter = PositionReference(offsetX: 0.5, offsetY: 1.0)
        static var topRight = PositionReference(offsetX: 1.0, offsetY: 1.0)
        
        static var centerLeft = PositionReference(offsetX: 0.0, offsetY: 0.5)
        static var center = PositionReference(offsetX: 0.5, offsetY: 0.5)
        static var centerRight = PositionReference(offsetX: 1.0, offsetY: 0.5)
    }
    
    /**
     Draws at the given point. active is a double specifically for animation
     */
    func draw(position: CGPoint, reference: PositionReference = .bottomLeft, active: Double = 1.0, fadeOutEnd: CGRect = CGRect(x: -10.0, y: -10.0, width: 1e7, height: 1e7), fadeOutLength: Double = 10.0, into encoder: MTLRenderCommandEncoder) {
        
        let ownSize = SIMD2<Float>(x: Float(size.width), y: Float(size.height))
        let lowerLeft = SIMD2<Float>(x: Float(position.x - reference.offsetX * size.width), y: Float(position.y - reference.offsetY * size.height))
        let upperRight = lowerLeft + ownSize
        
        let textureSize = SIMD2<Float>(repeating: 2048)
        let textureLowerLeft = SIMD2<Float>(x: Float(area.minX), y: Float(area.minY)) / textureSize
        let textureUpperRight = SIMD2<Float>(x: Float(area.maxX), y: Float(area.maxY)) / textureSize
        encoder.setFragmentTexture(atlas.texture, index: Int(HUDFragmentTextureBase.rawValue))
        
        let alpha = Float(active)
        
        // Extra float for alignment
        let coords: [HUDVertex] = [
            HUDVertex(x: lowerLeft.x, y: lowerLeft.y, tx: textureLowerLeft.x, ty: textureUpperRight.y),
            HUDVertex(x: upperRight.x, y: lowerLeft.y, tx: textureUpperRight.x, ty: textureUpperRight.y),
            HUDVertex(x: lowerLeft.x, y: upperRight.y, tx: textureLowerLeft.x, ty: textureLowerLeft.y),
            HUDVertex(x: upperRight.x, y: upperRight.y, tx: textureUpperRight.x, ty: textureLowerLeft.y)
        ]
        
        coords.withUnsafeBytes { bytes in
            encoder.setVertexBytes(bytes.baseAddress!, length: bytes.count, index: Int(HUDVertexBufferData.rawValue))
        }
        
        let fadeOutEndBox = (
            SIMD2<Float>(x: Float(fadeOutEnd.minX), y: Float(fadeOutEnd.minY)),
            SIMD2<Float>(x: Float(fadeOutEnd.maxX), y: Float(fadeOutEnd.maxY))
        )
        let fadeOutStartBox = (
            fadeOutEndBox.0 + SIMD2<Float>(repeating: Float(fadeOutLength)),
            fadeOutEndBox.1 - SIMD2<Float>(repeating: Float(fadeOutLength))
        )
        
        var fragmentParams = HUDFragmentParams(alpha: alpha, fadeOutStartBox: fadeOutStartBox, fadeOutEndBox: fadeOutEndBox)
        encoder.setFragmentBytes(&fragmentParams, length: MemoryLayout<HUDFragmentParams>.stride, index: Int(HUDFragmentBufferParams.rawValue))
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}
