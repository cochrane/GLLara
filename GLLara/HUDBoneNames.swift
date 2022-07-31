//
//  HUDBoneNames.swift
//  GLLara
//
//  Created by Torsten Kammer on 31.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

class HUDBoneNames {
    
    var drawersAncestors: [HUDTextDrawer] = []
    var drawersChildren: [HUDTextDrawer] = []
    var drawersSiblings: [HUDTextDrawer] = []
    var indexInSiblings = 0
    
    var drawerLeft = HUDTextDrawer.drawer(systemImage: "dpad.left.filled")
    var drawerUp = HUDTextDrawer.drawer(systemImage: "dpad.up.filled")
    var drawerDown = HUDTextDrawer.drawer(systemImage: "dpad.down.filled")
    var drawerRight = HUDTextDrawer.drawer(systemImage: "dpad.right.filled")
    
    var highlightedLeft = HUDTextDrawer.drawer(systemImage: "dpad.left.filled", highlighted: true)
    var highlightedUp = HUDTextDrawer.drawer(systemImage: "dpad.up.filled", highlighted: true)
    var highlightedDown = HUDTextDrawer.drawer(systemImage: "dpad.down.filled", highlighted: true)
    var highlightedRight = HUDTextDrawer.drawer(systemImage: "dpad.right.filled", highlighted: true)
    
    func update(bone: GLLItemBone) {
        drawersAncestors.removeAll()
        var parent = bone.parent
        while let currentParent = parent {
            drawersAncestors.append(HUDTextDrawer.drawer(string: currentParent.bone.name) )
            parent = currentParent.parent
        }
        
        drawersChildren.removeAll()
        var child = bone.children?.first
        while let currentChild = child {
            drawersChildren.append(HUDTextDrawer.drawer(string: currentChild.bone.name))
            child = currentChild.children?.first
        }
        
        drawersSiblings.removeAll()
        if let parent = bone.parent {
            drawersSiblings = parent.children.map { HUDTextDrawer.drawer(string: $0.bone.name) }
            if let index = parent.children.firstIndex(of: bone) {
                indexInSiblings = index
            } else {
                drawersSiblings.append( HUDTextDrawer.drawer(string: bone.bone.name) )
                indexInSiblings = drawersSiblings.count - 1
            }
        } else {
            drawersSiblings.append(HUDTextDrawer.drawer(string: bone.bone.name))
            indexInSiblings = 0
        }
    }
}
