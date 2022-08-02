//
//  HUDButtonDrawer.swift
//  GLLara
//
//  Created by Torsten Kammer on 31.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

class HUDButtonDrawer {
    
    private let drawerActive: HUDTextDrawer
    private let drawerInactive: HUDTextDrawer
    
    init(systemImage: String) {
        drawerActive = HUDTextDrawer.drawer(systemImage: systemImage, highlighted: true)
        drawerInactive = HUDTextDrawer.drawer(systemImage: systemImage, highlighted: false)
    }
    
    func draw(position: SIMD2<Float>, reference: HUDTextDrawer.PositionReference = .bottomLeft, highlighted: Bool, active: Float = 1.0, fadeOutEnd: HUDTextDrawer.Rectangle = HUDTextDrawer.Rectangle(lowerLeft: SIMD2<Float>(x: -10.0, y: -10.0), upperRight: SIMD2<Float>(x: 1e7, y: 1e7)), fadeOutLength: Float = 10.0, into encoder: MTLRenderCommandEncoder) {
        if highlighted {
            drawerActive.draw(position: position, reference: reference, active: active, fadeOutEnd: fadeOutEnd, fadeOutLength: fadeOutLength, into: encoder)
        } else {
            drawerInactive.draw(position: position, reference: reference, active: active, fadeOutEnd: fadeOutEnd, fadeOutLength: fadeOutLength, into: encoder)
        }
    }
    
    var size: SIMD2<Float> {
        return drawerInactive.size
    }
}
