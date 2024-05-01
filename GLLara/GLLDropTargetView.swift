//
//  GLLDropTargetView.swift
//  GLLara
//
//  Created by Torsten Kammer on 01.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLDropTargetView: NSView {
    private var dragDestination = GLLItemDragDestination()
    
    override func awakeFromNib() {
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard let windowController = window?.windowController as? GLLDocumentWindowController, let document = windowController.document as? GLLDocument else {
            return []
        }
        
        dragDestination.document = document;
        
        return dragDestination.itemDraggingEntered(sender)
    }
    
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let windowController = window?.windowController as? GLLDocumentWindowController, let document = windowController.document as? GLLDocument else {
            return false
        }
        
        dragDestination.document = document;
        
        do {
            try dragDestination.performItemDragOperation(sender)
            return true
        } catch let error as NSError {
            presentError(error)
            return false
        }
    }
}
