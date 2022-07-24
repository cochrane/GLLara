//
//  HUD.swift
//  GLLara
//
//  Created by Torsten Kammer on 24.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

/**
 One HUD belongs to one view drawer and draws everything that is important for it.
 */
class HUD {
    let drawer1 = HUDTextDrawer.drawer(string: "Hi there!")
    let drawer2 = HUDTextDrawer.drawer(systemImage: "cablecar.fill")
    
    func draw(size: CGSize, into encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(GLLResourceManager.shared.drawHudPipelineState)
        var screenSize = SIMD2<Float>(x: Float(size.width), y: Float(size.height))
        encoder.setVertexBytes(&screenSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        
        drawer1.draw(position: CGPoint(x: size.width / 2, y: size.height / 3), reference: .center, into: encoder)
        drawer2.draw(position: CGPoint(x: size.width / 2, y: 2 * size.height / 3), reference: .center, into: encoder)
    }
}
