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
    
    struct Rectangle {
        let lowerLeft: SIMD2<Float>
        let upperRight: SIMD2<Float>
    }
    
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
        
        func tryAdd(_ drawnText: DrawnText) -> Rectangle? {
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
                    
                    return Rectangle(lowerLeft: SIMD2<Float>(x: Float(xBegin), y: Float(beginLine)),
                                     upperRight: SIMD2<Float>(x: Float(xBegin + drawnText.width), y: Float(beginLine + drawnText.height)))
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
    private let area: Rectangle
    
    init(atlas: TextureAtlas, area: Rectangle) {
        self.atlas = atlas
        self.area = area
    }
    
    var size: SIMD2<Float> {
        return area.upperRight - area.lowerLeft
    }
    
    struct PositionReference {
        /// Relative offset from left/bottom. 0 means position refers to left/bottom edge, 1 means position refers to right/top edge
        let offset: SIMD2<Float>
        
        static var bottomLeft = PositionReference(offset: SIMD2<Float>(x: 0.0, y: 0.0))
        static var bottomCenter = PositionReference(offset: SIMD2<Float>(x: 0.5, y: 0.0))
        static var bottomRight = PositionReference(offset: SIMD2<Float>(x: 1.0, y: 0.0))
        
        static var topLeft = PositionReference(offset: SIMD2<Float>(x: 0.0, y: 1.0))
        static var topCenter = PositionReference(offset: SIMD2<Float>(x: 0.5, y: 1.0))
        static var topRight = PositionReference(offset: SIMD2<Float>(x: 1.0, y: 1.0))
        
        static var centerLeft = PositionReference(offset: SIMD2<Float>(x: 0.0, y: 0.5))
        static var center = PositionReference(offset: SIMD2<Float>(x: 0.5, y: 0.5))
        static var centerRight = PositionReference(offset: SIMD2<Float>(x: 1.0, y: 0.5))
    }
    
    /**
     Draws at the given point. active is a double specifically for animation
     */
    func draw(position: SIMD2<Float>, reference: PositionReference = .bottomLeft, active: Float = 1.0, fadeOutEnd: HUDTextDrawer.Rectangle = HUDTextDrawer.Rectangle(lowerLeft: SIMD2<Float>(x: -10.0, y: -10.0), upperRight: SIMD2<Float>(x: 1e7, y: 1e7)), fadeOutLength: Float = 10.0, into encoder: MTLRenderCommandEncoder) {
        
        let ownSize = size
        let lowerLeft = position - reference.offset * ownSize
        let upperRight = lowerLeft + ownSize
        
        let textureSize = SIMD2<Float>(repeating: 2048)
        let textureLowerLeft = area.lowerLeft / textureSize
        let textureUpperRight = area.upperRight / textureSize
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
            fadeOutEnd.lowerLeft,
            fadeOutEnd.upperRight
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
