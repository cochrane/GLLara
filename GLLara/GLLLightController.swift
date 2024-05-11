//
//  GLLLightController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Cocoa

/**
 * Source list controller for a single light (whether diffuse or ambient).
 */
@objc class GLLLightController : NSObject, NSOutlineViewDataSource {
    init(light: NSManagedObject, parentController: AnyObject) {
        self.light = light
        self.parentController = parentController
    }
    
    let light: NSManagedObject
    @objc var representedObject: NSManagedObject {
        return light
    }
    @objc weak var parentController: AnyObject?
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return "" // Should never come here
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if light.entity.name == "GLLAmbientLight" {
            return NSLocalizedString("Ambient", comment: "source view - lights");
        } else {
            return String(format: NSLocalizedString("Diffuse %@", comment: "source view - lights"), light.value(forKey: "index") as! NSNumber)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}
