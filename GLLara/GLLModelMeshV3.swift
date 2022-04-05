//
//  GLLModelMeshV3.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLModelMeshV3: GLLModelMesh {
    // This version does not have tangents in the file anymore
    override var hasTangentsInFile: Bool {
        return true
    }
}
