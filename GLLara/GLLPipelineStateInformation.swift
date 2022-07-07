//
//  GLLPipelineStateInformation.swift
//  GLLara
//
//  Created by Torsten Kammer on 03.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

/**
 * Arrange pipeline state and associated functions. Needed so we can
 * initialize the argument buffer correctly.
 */
struct GLLPipelineStateInformation {
    let pipelineState: MTLRenderPipelineState
    let vertexProgram: MTLFunction
    let fragmentProgram: MTLFunction
}
