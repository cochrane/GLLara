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
    let boneNameHud = HUDBoneNames()
    
    func draw(size: SIMD2<Float>, into encoder: MTLRenderCommandEncoder) {        encoder.setRenderPipelineState(GLLResourceManager.shared.drawHudPipelineState)
        var vertexParams = HUDVertexParams(screenSize: size)
        encoder.setVertexBytes(&vertexParams, length: MemoryLayout<HUDVertexParams>.stride, index: 1)

        controllerModeHud.draw(size: size, into: encoder)
        boneNameHud.draw(size: size, into: encoder)
    }
    
    var runningAnimation: Bool {
        return controllerModeHud.runningAnimation || boneNameHud.runningAnimation
    }
    
    func update(delta: TimeInterval) {
        controllerModeHud.update(delta: delta)
        boneNameHud.update(delta: delta)
    }
    
    func setCurrent(bone: GLLItemBone) {
        boneNameHud.setNext(bone: bone)
    }
    
    func setCurrentNoAnimation(bone: GLLItemBone) {
        boneNameHud.setExplicit(bone: bone)
    }
}
