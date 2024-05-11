//
//  GLLLightsListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

/**
 * Source list controller for a list of lights, and direct child of the root.
 */
@objc class GLLLightsListController: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @objc init(managedObjectContext: NSManagedObjectContext, outlineView: NSOutlineView) {
        self.managedObjectContext = managedObjectContext
        self.outlineView = outlineView
        
        super.init()
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "GLLLight")
        request.sortDescriptors = [ NSSortDescriptor(key: "index", ascending: true) ]
        
        lights = try! managedObjectContext.fetch(request).map { GLLLightController(light: $0, parentController: self) }
    }
    
    @objc let managedObjectContext: NSManagedObjectContext
    @objc let outlineView: NSOutlineView
    
    var lights: [GLLLightController] = []
    
    @objc var allSelectableControllers: [GLLLightController] {
        return lights
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return lights[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return NSLocalizedString("Lights", comment: "source view header")
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return lights.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return false
    }
}
