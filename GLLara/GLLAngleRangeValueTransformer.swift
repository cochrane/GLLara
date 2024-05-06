//
//  GLLAngleRangeValueTransformer.m
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//
import Foundation

/*
 * Exactly what it says on the tin.
 * The idea is that rotations are stored from 0…2pi here, but for sliders, you really want -pi…+pi instead. This transformer solves that issue.
 */
@objc class GLLAngleRangeValueTransformer: ValueTransformer {
    @objc override class func allowsReverseTransformation() -> Bool {
        return true
    }
    @objc override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        let double = (value as! NSNumber).doubleValue
        if double > Double.pi {
            return double - Double.pi * 2
        } else {
            return double
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        let double = (value as! NSNumber).doubleValue
        if double < 0.0 {
            return double + Double.pi * 2
        } else {
            return double
        }    }
}
