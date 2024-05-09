//
//  GLLOptionalPartController.m
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Cocoa

/*!
 * Item controller for the optional parts of a model (if it has any). This just
 * shows one single source list entry, no children; this entry shows a list of
 * optional model parts in its detail view.
 */
@objc class GLLOptionalPartController: NSObject, NSOutlineViewDataSource {
    
    @objc init(item: GLLItem, parent: AnyObject) {
        representedObject = GLLItemOptionalPartMarker(item: item)
        parentController = parent
    }
    
    @objc var item: GLLItem {
        return representedObject.item
    }
    @objc weak var parentController: AnyObject?
    @objc let representedObject: GLLItemOptionalPartMarker
    
    @objc func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        NSLocalizedString("Optional parts", comment: "source view optional parts")
    }
    
    @objc func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    @objc func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return 0
    }
}
