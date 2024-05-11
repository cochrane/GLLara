//
//  GLLBoneListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Cocoa

/*!
 * Source list controller for a list of bones. Child of an item.
 * Also includes the bones of subitems. It creates all bone controllers, not
 * just the root bones. The bone controllers then access it to get their
 * children.
 */
@objc class GLLBoneListController: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    init(item: GLLItem, outlineView: NSOutlineView, parent: AnyObject) {
        self.item = item
        self.outlineView = outlineView
        self.parentController = parent
        
        super.init()
        
        boneControllers = item.combinedBones().map { GLLBoneController(bone: ($0 as! GLLItemBone), listController: self) }
        rootBoneControllers = boneControllers.filter { $0.bone.parent == nil }
        
        startObservingChildItems(of: item)
    }
    
    private func startObservingChildItems(of item: GLLItem) {
        observations[item] = item.observe(\GLLItem.childItems, options: [.new, .old, .initial]) { _, change in
            for item in (change.oldValue ?? []) ?? [] {
                self.stopObservingChildItems(of: item as! GLLItem)
            }
            for item in (change.newValue ?? []) ?? [] {
                self.startObservingChildItems(of: item as! GLLItem)
            }
            
            // Run only after delay, to ensure that everything has been set correctly by the time this code gets active.
            DispatchQueue.main.async { [self] in
                boneControllers = item.combinedBones().map { GLLBoneController(bone: ($0 as! GLLItemBone), listController: self) }
                rootBoneControllers = boneControllers.filter { $0.bone.parent == nil }
                
                outlineView.reloadItem(self, reloadChildren: true)
            }
        }
    }
    
    private func stopObservingChildItems(of item: GLLItem) {
        observations.removeValue(forKey: item)
        for child in item.childItems {
            stopObservingChildItems(of: child as! GLLItem)
        }
    }
    
    @objc var item: GLLItem
    @objc var allSelectableControllers: [GLLBoneController] {
        return boneControllers;
    }
    @objc var boneControllers: [GLLBoneController] = []
    @objc let outlineView: NSOutlineView
    @objc weak var parentController: AnyObject?
    
    @objc private var rootBoneControllers: [GLLBoneController] = []
    
    private var observations: [GLLItem : NSKeyValueObservation] = [:]
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return rootBoneControllers[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return NSLocalizedString("Bones", comment: "source view header")
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return rootBoneControllers.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return false
    }
}
