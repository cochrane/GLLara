//
//  GLLColorValueTransformer.swift
//  GLLara
//
//  Created by Torsten Kammer on 11.09.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa

// 1. Subclass from `NSSecureUnarchiveFromDataTransformer`
@objc(GLLColorValueTransformer)
final class GLLColorValueTransformer: NSSecureUnarchiveFromDataTransformer {

    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: GLLColorValueTransformer.self))

    // 2. Make sure `UIColor` is in the allowed class list.
    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSColor.self]
    }

    /// Registers the transformer.
    @objc public static func registerTransformer() {
        let transformer = GLLColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
