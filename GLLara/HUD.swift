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
    let controllerModeHud = HUDControllerMode()
    
    func draw(size: CGSize, into encoder: MTLRenderCommandEncoder) {        encoder.setRenderPipelineState(GLLResourceManager.shared.drawHudPipelineState)
        var vertexParams = HUDVertexParams(screenSize: SIMD2<Float>(x: Float(size.width), y: Float(size.height)))
        encoder.setVertexBytes(&vertexParams, length: MemoryLayout<HUDVertexParams>.stride, index: 1)

        controllerModeHud.draw(size: size, into: encoder)
    }
    
    var runningAnimation: Bool {
        return controllerModeHud.runningAnimation
    }
    
    func update(delta: TimeInterval) {
        controllerModeHud.update(delta: delta)
    }
}
