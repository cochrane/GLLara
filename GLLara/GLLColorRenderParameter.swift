//
//  GLLColorRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation
import CoreData

/**
 * @abstract A render parameter whose value is a color.
 * @discussion These paramaters are new additions; XNALara has only float
 * parameters.
 */
@objc(GLLColorRenderParameter)
public class GLLColorRenderParameter: GLLRenderParameter {
    @NSManaged public var value: NSColor!
    
    var colorValue: vector_float4 {
        return value.rgbaComponents128Bit
    }
}
