//
//  GLLModelMeshV4.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.07.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLModelMeshV4: GLLModelMeshV3 {
    // This format has a variable number of bones
    // How TF am I supposed to implement that?
    override var hasVariableBonesPerVertex: Bool {
        return true
    }
}
