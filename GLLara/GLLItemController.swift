//
//  GLLItemController.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Cocoa

/*!
 * Source list controller for an item.
 */
@objc class GLLItemController: GLLItemListController {
    @objc convenience init(item: GLLItem, outlineView: NSOutlineView, parent: AnyObject) {
        self.init(item: item, outlineView: outlineView, parent: parent, showBones: true)
    }
    
    init(item: GLLItem, outlineView: NSOutlineView, parent: AnyObject, showBones: Bool) {
        super.init(managedObjectContext: item.managedObjectContext!, outlineView: outlineView, parentItem: item)
        
        meshListController = GLLMeshListController(item: item, parent: self)
        if showBones {
            boneListController = GLLBoneListController(item: item, outlineView: outlineView, parent: self)
        }
        if item.hasOptionalParts {
            optionalPartsController = GLLOptionalPartController(item: item, parent: self)
        }
    }
    
    @objc override var representedObject: AnyObject? {
        return item
    }
    
    @objc override var allSelectableControllers: [AnyObject] {
        var controllers: [AnyObject] = []
        if let meshListController {
            controllers.append(contentsOf: meshListController.allSelectableControllers)
        }
        if let boneListController {
            controllers.append(contentsOf: boneListController.allSelectableControllers)
        }
        if let optionalPartsController {
            controllers.append(optionalPartsController)
        }
        for childrenController in itemControllers {
            controllers.append(contentsOf: childrenController.allSelectableControllers)
        }
        return controllers
    }
    @objc weak var parentController: AnyObject?
    
    var meshListController: GLLMeshListController? = nil
    var boneListController: GLLBoneListController? = nil
    var optionalPartsController: GLLOptionalPartController? = nil
    
    override func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        var result = 0
        if meshListController != nil {
            result += 1
        }
        if boneListController != nil {
            result += 1
        }
        if optionalPartsController != nil {
            result += 1
        }
        result += itemControllers.count
        return result
    }
    
    override func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return self.item!.displayName
    }
    
    override func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        var relativeIndex = index
        if let meshListController {
            if relativeIndex == 0 {
                return meshListController
            }
            relativeIndex -= 1
        }
        if let boneListController {
            if relativeIndex == 0 {
                return boneListController
            }
            relativeIndex -= 1
        }
        if let optionalPartsController {
            if relativeIndex == 0 {
                return optionalPartsController
            }
            relativeIndex -= 1
        }
        return itemControllers[relativeIndex]
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return true
    }
    
    override func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return false
    }
    
    override func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem some: Any?) {
        if let name = object as? String {
            self.item!.displayName = name
        }
    }
}
