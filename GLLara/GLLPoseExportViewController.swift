//
//  GLLPoseExportViewController.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLPoseExportViewController: NSViewController {
    
    convenience init() {
        self.init(nibName: "GLLPoseExportViewController", bundle: nil)
    }
    
    @objc dynamic var selectionMode: UInt = 0
    @objc dynamic var exportUnusedBones: Bool = false
    @objc dynamic var exportOnlySelectedBones: Bool {
        get {
            return selectionMode == 0
        }
        set {
            if newValue {
                selectionMode = 0
            } else {
                selectionMode = 1
            }
        }
    }
}
