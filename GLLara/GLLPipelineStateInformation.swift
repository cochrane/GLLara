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
@objc class GLLPipelineStateInformation: NSObject {
    @objc var pipelineState: MTLRenderPipelineState! = nil
    @objc var fragmentProgram: MTLFunction! = nil
    @objc var vertexProgram: MTLFunction! = nil
}
