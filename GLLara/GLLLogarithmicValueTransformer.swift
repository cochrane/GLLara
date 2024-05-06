//
//  GLLLogarithmicValueTransformer.swift
//  GLLara
//
//  Created by Torsten Kammer on 16.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation

/**
 * @abstract Logarithmic Value Transformer
 * @discussion Used to allow setting of things like scales with a slider
 * that uses logarithmic scale. works in base 10.
 */
@objc class GLLLogarithmicValueTransformer: ValueTransformer {
    @objc override class func allowsReverseTransformation() -> Bool {
        return true
    }
    @objc override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        return log10((value as! NSNumber).doubleValue)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        return pow(10.0, (value as! NSNumber).doubleValue)
    }
}
