//
//  GLLMeshController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Cocoa

/**
 * @abstract Source list controller for a mesh.
 */
@objc class GLLMeshController : NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    init(mesh: GLLItemMesh, parentController: AnyObject) {
        self.mesh = mesh
        self.parentController = parentController
    }
    
    let mesh: GLLItemMesh
    @objc weak var parentController: AnyObject?
    @objc var representedObject: GLLItemMesh {
        return mesh
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return mesh.displayName
    }
    
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        if let newName = object as? String {
            mesh.displayName = newName
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return true
    }

}
