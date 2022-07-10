//
//  GLLAppDelegate.swift
//  GLLara
//
//  Created by Torsten Kammer on 09.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLAppDelegate: NSObject, NSApplicationDelegate {
    
    var preferencesWindowController: GLLPreferencesWindowController? = nil
    
    override class func awakeFromNib() {
        UserDefaults.standard.register(defaults: [
            GLLPrefUseAnisotropy: true,
            GLLPrefUseMSAA: false,
            GLLPrefAnisotropyAmount: 4,
            GLLPrefMSAAAmount: 0,
            GLLPrefObjExportIncludesTransforms: true,
            GLLPrefObjExportIncludesVertexColors: false,
            GLLPrefPoseExportIncludesUnused: false,
            GLLPrefPoseExportOnlySelected: true,
            GLLPrefShowSkeleton: true
        ])
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    @IBAction func openPreferences(sender: Any?) {
        if (preferencesWindowController == nil) {
            preferencesWindowController = GLLPreferencesWindowController()
        }
        
        preferencesWindowController!.showWindow(sender)
    }
}
