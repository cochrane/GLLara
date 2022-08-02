//
//  GLLItemBoneExtensions.swift
//  GLLara
//
//  Created by Torsten Kammer on 02.08.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItemBone {
    
    func parent(skippingUnused: Bool) -> GLLItemBone? {
        var usedParent = self.parent
        while let current = usedParent {
            if !skippingUnused || !current.bone.name.hasPrefix("unused") {
                return current
            }
            usedParent = current.parent
        }
        return nil
    }
    
    func children(skippingUnused: Bool) -> [GLLItemBone] {
        guard let children = children else {
            return []
        }
        var result: [GLLItemBone] = []
        for child in children {
            if skippingUnused && child.bone.name.hasPrefix("unused") {
                result.append(contentsOf: child.children(skippingUnused: true))
            } else {
                result.append(child)
            }
        }
        return result
    }
    
    func firstChild(skippingUnused: Bool) -> GLLItemBone? {
        guard let children = children else {
            return nil
        }
        for child in children {
            if skippingUnused && child.bone.name.hasPrefix("unused") {
                if let usedDescendant = child.firstChild(skippingUnused: true) {
                    return usedDescendant
                }
            } else {
                return child
            }
        }
        return nil
    }
    
    func siblings(skippingUnused: Bool) -> [GLLItemBone]? {
        return parent(skippingUnused: skippingUnused)?.children(skippingUnused: skippingUnused)
    }
    
}
