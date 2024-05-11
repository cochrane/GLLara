//
//  GLLMeshListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Cocoa

/**
 * Source list controller for a list of meshes. Child of an item.
 */
@objc class GLLMeshListController : NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    init(item: GLLItem, parent: AnyObject) {
        self.item = item
        self.parentController = parent
        
        super.init()
        
        self.meshControllers = item.meshes.map { GLLMeshController(mesh: ($0 as! GLLItemMesh), parentController: self)}
    }
    
    let item: GLLItem
    @objc weak var parentController: AnyObject?
    @objc var allSelectableControllers: [GLLMeshController]! {
        return meshControllers
    }
    
    var meshControllers: [GLLMeshController]! = []
    
    @objc func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return meshControllers[index]
    }
    
    @objc func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        NSLocalizedString("Meshes", comment: "source view header")
    }
    
    @objc func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    @objc func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return meshControllers.count
    }
    
    @objc func outlineView(_ view: NSOutlineView, shouldSelectItem: Any) -> Bool {
        return false
    }
}
