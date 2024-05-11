//
//  GLLItemListController.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLItemListController: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @objc convenience init(managedObjectContext: NSManagedObjectContext, outlineView: NSOutlineView) {
        self.init(managedObjectContext: managedObjectContext, outlineView: outlineView, parentItem: nil)
    }
    
    init(managedObjectContext: NSManagedObjectContext, outlineView: NSOutlineView, parentItem item: GLLItem?) {
        self.managedObjectContext = managedObjectContext
        self.outlineView = outlineView
        self.item = item
        
        super.init()
        
        observation = NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main) { [weak self] notification in
            guard let self else {
                return
            }
            
            let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []
            itemControllers.removeAll {
                deletedObjects.contains($0.item!)
            }
            let addedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
            let newItems = addedObjects.filter {
                // Only top-level-items that haven't been already deleted again
                guard let item = $0 as? GLLItem else {
                    return false
                }
                return item.parent == self.item && !deletedObjects.contains($0)
            }
            itemControllers.append(contentsOf: newItems.map { GLLItemController(item: $0 as! GLLItem, outlineView: outlineView, parent: self, showBones: self.item != nil)})
            itemControllers.sort { $0.item!.displayName < $1.item!.displayName }
            outlineView.reloadItem(self, reloadChildren: true)
        }
        
        let initialRequest = NSFetchRequest<GLLItem>(entityName: "GLLItem")
        initialRequest.sortDescriptors = [ NSSortDescriptor(key: "displayName", ascending: true) ]
        initialRequest.predicate = NSPredicate(format: "parent == %@", item ?? NSNull())
        let initial = try! managedObjectContext.fetch(initialRequest)
        itemControllers = initial.map {
            GLLItemController(item: $0, outlineView: outlineView, parent: self, showBones: self.item != nil)
        }
    }
    
    deinit {
        if let observation {
            NotificationCenter.default.removeObserver(observation)
        }
    }
    
    @objc let managedObjectContext: NSManagedObjectContext
    @objc let outlineView: NSOutlineView
    @objc var itemControllers: [GLLItemController] = []
    @objc var allSelectableControllers: [AnyObject] {
        return itemControllers.flatMap { $0.allSelectableControllers }
    }
    
    let item: GLLItem?
    
    var observation: AnyObject? = nil
    
    @objc var representedObject: AnyObject? {
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return itemControllers[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return NSLocalizedString("Items", comment: "source view header")
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return itemControllers.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        return false
    }
}
