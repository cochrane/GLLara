//
//  GLLSettingsListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

/**
 * Source list controller for a list of settings, and direct child of the root.
 * Currently, there are no settings.
 */
@objc class GLLSettingsListController: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @objc init(managedObjectContext: NSManagedObjectContext, outlineView: NSOutlineView) {
        self.managedObjectContext = managedObjectContext
    }
    
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var allSelectableControllers: [NSObject] {
        return []
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        assert(false)
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return NSLocalizedString("Settings", comment: "source view header")
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return true
    }
}
