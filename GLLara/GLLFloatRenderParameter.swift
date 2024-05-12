//
//  GLLFloatRenderParameter.swift
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation
import CoreData

/**
 * @abstract A render parameter whose value is a single real number.
 * @discussion This includes all XNALara-specific render parameters, but also
 * a few added myself.
 */
@objc(GLLFloatRenderParameter)
public class GLLFloatRenderParameter: GLLRenderParameter {
    @NSManaged public var value: Float
}
