//
//  GLLBoneController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Cocoa

/**
 * @abstract Source list controller for a bone.
 * @discussion  Gets its children from the parent bone list controller. If it
 * came from a child item, the name shown is altered to reflect this.
 */
@objc class GLLBoneController: NSObject, NSOutlineViewDataSource {
    let bone: GLLItemBone
    @objc var representedObject: GLLItemBone {
        return bone
    }
    @objc weak var listController: GLLBoneListController!
    
    init(bone: GLLItemBone, listController: GLLBoneListController) {
        self.bone = bone
        self.listController = listController
    }
    
    private weak var parentControllerCached: AnyObject?
    @objc var parentController: AnyObject {
        if let parent = parentControllerCached {
            return parent
        }
        if let parent = bone.parent {
            let parentController = listController.boneControllers.first { ($0 as! GLLBoneController).bone == parent }
            parentControllerCached = parentController as AnyObject?
            return parentController as AnyObject
        } else {
            parentControllerCached = listController
            return listController
        }
    }
    
    @objc var childBoneControllers: [GLLBoneController] {
        let hideUnused = UserDefaults.standard.bool(forKey: "hideUnusedBones")
        if hideUnused {
            return listController.boneControllers.filter({ item in
                guard let controller = item as? GLLBoneController else {
                    return false
                }
                if controller.bone.bone.name.hasPrefix("unused") {
                    return false
                }
                return isDescendantSkippingUnknown(bone: controller.bone)
            }) as! [GLLBoneController]
        } else {
            return listController.boneControllers.filter({ item in
                guard let controller = item as? GLLBoneController else {
                    return false
                }
                return controller.bone.parent == bone
            }) as! [GLLBoneController]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return childBoneControllers[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        let result: String
        if bone.item != listController.item {
            result = String(format: NSLocalizedString("%@ (%@)", comment: "Bone from other model"), bone.bone.name, bone.item.displayName)
        } else {
            result = bone.bone.name
        }
        
        if bone.hasNonDefaultTransform {
            return AttributedString(result, attributes: AttributeContainer([.font : NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]))
        } else {
            return result
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return childBoneControllers.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return !childBoneControllers.isEmpty
    }
    
    func isDescendantSkippingUnknown(bone otherBone: GLLItemBone) -> Bool {
        guard let parent = otherBone.parent else {
            return false
        }
        
        if parent == bone {
            return true
        }
        if otherBone.bone.name.starts(with: "unknown") {
            return isDescendantSkippingUnknown(bone: parent)
        }
        return false
    }
}

