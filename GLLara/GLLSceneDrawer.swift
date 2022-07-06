//
//  GLLSceneDrawer.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa
import CoreData

@objc class GLLSceneDrawer: NSObject {
    
    @objc init(document: GLLDocument) {
        self.document = document
        skeletonDrawer = GLLSkeletonDrawer(resourceManager: GLLResourceManager.shared())
        
        super.init()
        
        managedObjectContextObserver = NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: document.managedObjectContext, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else {
                return
            }
            
            let deletedObjects = notification.userInfo![NSDeletedObjectsKey] as! NSSet
            self.itemDrawers.removeAll { drawer in
                deletedObjects.contains(drawer.item)
            }
            
            let insertedObjects = notification.userInfo![NSInsertedObjectsKey] as! NSSet
            for newItem in insertedObjects {
                if (deletedObjects.contains(newItem)) {
                    continue;
                }
                
                if let gllitem = newItem as? GLLItem {
                    self.addDrawer(for: gllitem);
                }
            }
        }
        
        drawStateNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name.GLLDrawStateChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.notifyRedraw()
        }
        
        // Load existing items
        let allItemsRequest = GLLItem.fetchRequest()
        let allItems = try! document.managedObjectContext?.fetch(allItemsRequest)
        for item in allItems! {
            addDrawer(for: item as! GLLItem)
        }
        
    }
    
    deinit {
        if let observer = managedObjectContextObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = drawStateNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    weak var document: GLLDocument?
    
    @objc var managedObjectContext: NSManagedObjectContext? {
        return document?.managedObjectContext
    }
    @objc var resourceManager: GLLResourceManager {
        return GLLResourceManager.shared()
    }
    
    var selectedBones: [GLLItemBone] {
        set {
            skeletonDrawer.selectedBones = newValue
            notifyRedraw()
        }
        get {
            return skeletonDrawer.selectedBones
        }
    }
    
    @objc func draw(showingSelection: Bool, into commandEncoder: MTLRenderCommandEncoder) {
        for itemDrawer in itemDrawers {
            itemDrawer.draw(into: commandEncoder, blended: false)
        }
        
        if showingSelection {
            skeletonDrawer.draw(into: commandEncoder)
        }
    }
    
    func notifyRedraw() {
        NotificationCenter.default.post(name: NSNotification.Name.GLLSceneDrawerNeedsUpdate, object: self)
    }
    
    private var itemDrawers: [GLLItemDrawer] = []
    private let skeletonDrawer: GLLSkeletonDrawer
    private var drawStateNotificationObserver: Any? = nil
    private var managedObjectContextObserver: Any? = nil
    
    private func addDrawer(for item: GLLItem) {
        do {
            let drawer = try GLLItemDrawer(item: item, sceneDrawer: self)
            if drawer.replacedTextures.count > 0 {
                document!.notifyTexturesNotLoaded(drawer.replacedTextures)
            }
            itemDrawers.append(drawer)
        } catch {
            NSApp.presentError(error)
            if item.objectID.isTemporaryID {
                // Temporary ID means this was not loaded from a file. Get rid of it.
                item.managedObjectContext?.delete(item)
            }
        }
    }
    
}
