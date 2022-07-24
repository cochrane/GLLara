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
        
        init(text: NSAttributedString) {
            self.attributedString = text
            
            // Find size
            let frame = text.boundingRect(with: CGSize(width: 2048 - 2*HUDTextDrawer.capsulePaddingLeftRight, height: 2048), options: [ .truncatesLastVisibleLine ], context: nil)
            
            height = max(Int(ceil(frame.height)), HUDTextDrawer.capsuleHeight)
            width = Int(ceil(frame.width)) + 2*HUDTextDrawer.capsulePaddingLeftRight
            data = Data(count: height*width*4)
    
            // Create graphics context
            let colorSpace = CGColorSpaceCreateDeviceRGB();
            data.withUnsafeMutableBytes { bytes in
                let cgContext = CGContext(data: bytes.baseAddress!, width: self.width, height: self.height, bitsPerComponent: 8, bytesPerRow: self.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue + CGImageByteOrderInfo.order32Little.rawValue )!;

                // Draw the capsule
                cgContext.beginPath()
                cgContext.move(to: CGPoint(x:0, y:CGFloat(height) - capsuleCornerRadius))
                cgContext.addArc(tangent1End: CGPoint(x:0, y:CGFloat(height)),
                                 tangent2End: CGPoint(x:capsuleCornerRadius, y:CGFloat(height)),
                                 radius: capsuleCornerRadius)
                cgContext.addLine(to: CGPoint(x:CGFloat(width) - capsuleCornerRadius, y:CGFloat(height)))
                cgContext.addArc(tangent1End: CGPoint(x:CGFloat(width), y:CGFloat(height)),
                                 tangent2End: CGPoint(x:CGFloat(width), y:CGFloat(height) - capsuleCornerRadius),
                                 radius: capsuleCornerRadius)
                cgContext.addLine(to: CGPoint(x:CGFloat(width), y: capsuleCornerRadius))
                cgContext.addArc(tangent1End: CGPoint(x: CGFloat(width), y: 0),
                                 tangent2End: CGPoint(x: CGFloat(width) - capsuleCornerRadius, y: 0),
                                 radius: capsuleCornerRadius)
                cgContext.addLine(to: CGPoint(x:capsuleCornerRadius, y: 0))
                cgContext.addArc(tangent1End: CGPoint(x:0, y:0),
                                 tangent2End: CGPoint(x:0, y:capsuleCornerRadius),
                                 radius: capsuleCornerRadius)
                cgContext.closePath()
                cgContext.setFillColor(gray: 1.0, alpha: 0.5)
                cgContext.fillPath()
                
                // Draw the text
                let nsContext = NSGraphicsContext(cgContext: cgContext, flipped: false)
                let oldContext = NSGraphicsContext.current
                NSGraphicsContext.current = nsContext
                
                let shadow = NSShadow()
                shadow.shadowOffset = NSSize(width: 0, height: 0)
                shadow.shadowBlurRadius = 3.0
                shadow.shadowColor = NSColor.white
                shadow.set()
                
                text.draw(with: NSMakeRect(CGFloat(capsulePaddingLeftRight), capsuleBaseline, frame.width, frame.height), options: [ .truncatesLastVisibleLine ])
                
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
    
    static func drawer(string: String) -> HUDTextDrawer {
        return drawer(attributedString: NSAttributedString(string: string))
    }
    
    static func drawer(systemImage: String) -> HUDTextDrawer {
        let attachment = NSTextAttachment()
        attachment.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        
        return drawer(attributedString: NSAttributedString(attachment: attachment))
    }
    
    static func drawer(attributedString: NSAttributedString) -> HUDTextDrawer {
        // Adjust attributed string to match what we expect
        
        let adjustedString = NSMutableAttributedString(attributedString: attributedString)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 25.0, weight: .bold),
        ]
        
        adjustedString.addAttributes(attributes, range: NSRange(location: 0, length: adjustedString.length))
        
        if let drawer = drawers[adjustedString] {
            return drawer
        }
        
        // Need to draw and insert into a texture atlas
        let drawnText = DrawnText(text: adjustedString)
        for textureAtlas in textureAtlases {
            if let rect = textureAtlas.tryAdd(drawnText) {
                let drawer = HUDTextDrawer(atlas: textureAtlas, area: rect)
                drawers[adjustedString] = drawer
                return drawer
            }
        }
        // No free space found, gotta open a new texture atlas
        let newAtlas = TextureAtlas()
        textureAtlases.append(newAtlas)
        let rect = newAtlas.tryAdd(drawnText)!
        
        let drawer = HUDTextDrawer(atlas: newAtlas, area: rect)
        drawers[adjustedString] = drawer
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
    func draw(position: CGPoint, reference: PositionReference = .bottomLeft, active: Double = 1.0, clippedTo: CGRect = CGRect(x: 0.0, y: 0.0, width: CGFloat.infinity, height: CGFloat.infinity), clipFalloff: Double = 10.0, into encoder: MTLRenderCommandEncoder) {
        
        let ownSize = SIMD2<Float>(x: Float(size.width), y: Float(size.height))
        let lowerLeft = SIMD2<Float>(x: Float(position.x - reference.offsetX * size.width), y: Float(position.y - reference.offsetY * size.height))
        let upperRight = lowerLeft + ownSize
        
        let textureSize = SIMD2<Float>(repeating: 2048)
        let textureLowerLeft = SIMD2<Float>(x: Float(area.minX), y: Float(area.minY)) / textureSize
        let textureUpperRight = SIMD2<Float>(x: Float(area.maxX), y: Float(area.maxY)) / textureSize
        encoder.setFragmentTexture(atlas.texture, index: 0)
        
        
        let coords: [Float32] = [
            lowerLeft.x, lowerLeft.y, textureLowerLeft.x, textureUpperRight.y,
            upperRight.x, lowerLeft.y, textureUpperRight.x, textureUpperRight.y,
            lowerLeft.x, upperRight.y, textureLowerLeft.x, textureLowerLeft.y,
            upperRight.x, upperRight.y, textureUpperRight.x, textureLowerLeft.y
        ]
        
        coords.withUnsafeBytes { bytes in
            encoder.setVertexBytes(bytes.baseAddress!, length: bytes.count, index: 0)
        }
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}
