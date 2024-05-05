//
//  GLLItemDragDestination.swift
//  GLLara
//
//  Created by Torsten Kammer on 01.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

@objc class GLLItemDragDestination: NSObject {
    @objc weak var document: GLLDocument? = nil
    
    @objc func itemDraggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard document != nil, let pasteboardItems = sender.draggingPasteboard.pasteboardItems else {
            return []
        }
        
        for item in pasteboardItems {
            guard let urlAsString = item.string(forType: .fileURL) else {
                return []
            }
            guard let url = URL(string: urlAsString) else {
                return []
            }

            if !isObjectFile(url: url) && !(isPoseFile(url: url) && itemForPose != nil) && !isImagePath(url: url) {
                return []
            }
        }
        
        return [.copy]
    }
    
    @objc func performItemDragOperation(_ sender: NSDraggingInfo) throws {
        guard let document = document, let pasteboardItems = sender.draggingPasteboard.pasteboardItems else {
            throw NSError(domain: "Pasteboard", code: 0)
        }
        
        for item in pasteboardItems {
            guard let urlAsString = item.string(forType: .fileURL), let url = URL(string: urlAsString) else {
                throw NSError(domain: "Pasteboard", code: 0)
            }

            if isImagePath(url: url) {
                try document.addImagePlane(url)
            } else if isPoseFile(url: url) {
                guard let item = itemForPose else {
                    throw NSError(domain: "Pasteboard", code: 0)
                }
                try item.loadPose(url: url)
            } else {
                try document.addModel(at: url)
            }
        }
    }
    
    func isObjectFile(url: URL) -> Bool {
        let extensions = [ ".mesh", ".mesh.ascii", ".xps", ".obj", ".gltf", ".glob" ]
        return extensions.contains { url.lastPathComponent.hasSuffix($0) }
    }
    
    func isPoseFile(url: URL) -> Bool {
        let extensions = [ ".pose" ]
        return extensions.contains { url.lastPathComponent.hasSuffix($0) }
    }
    
    func isImagePath(url: URL) -> Bool {
        if url.pathExtension == ".dds" {
            return true
        }
        
        do {
            let contentTypeValues = try url.resourceValues(forKeys: [.contentTypeKey])
            guard let typeId = contentTypeValues.contentType else {
                return false
            }
            let typeIdentifiers = CGImageSourceCopyTypeIdentifiers() as! [String]
            return typeIdentifiers.contains(typeId.identifier)
        } catch {
            return false
        }
    }
    
    private var itemForPose: GLLItem? {
        guard let document = self.document else {
            return nil
        }
        
        if document.selection.countOfSelectedItems() == 1 {
            return document.selection.objectInSelectedItems(at: 0)
        }
        
        // Okay, more complicated: Check if there is only item in the file
        let itemRequest = NSFetchRequest<GLLItem>(entityName: "GLLItem")
        itemRequest.predicate = NSPredicate(format: "parent == nil")
        let rootItems = try! document.managedObjectContext!.fetch(itemRequest)
        if rootItems.count == 1 {
            return rootItems[0]
        }
        return nil
    }
}
