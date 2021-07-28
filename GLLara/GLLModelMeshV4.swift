//
//  GLLModelMeshV4.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.07.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLModelMeshV4: GLLModelMeshV3 {
    // This format has two extra bytes between texture coords and bone weights.
    // Why? Who knows. It's not like anybody documents this shit.
    override var hasV4ExtraBytes: Bool {
        return true
    }
}
