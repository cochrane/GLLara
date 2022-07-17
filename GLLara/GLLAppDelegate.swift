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
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            GLLPrefUseAnisotropy: true,
            GLLPrefUseMSAA: false,
            GLLPrefAnisotropyAmount: 4,
            GLLPrefMSAAAmount: 0,
            GLLPrefObjExportIncludesTransforms: true,
            GLLPrefObjExportIncludesVertexColors: false,
            GLLPrefPoseExportIncludesUnused: false,
            GLLPrefPoseExportOnlySelected: true,
            GLLPrefShowSkeleton: true,
            GLLPrefHideUnusedBones: true,
            GLLPrefSpaceMouseSpeedTranslation: 1,
            GLLPrefSpaceMouseDeadzoneTranslation: 0.0,
            GLLPrefSpaceMouseSpeedRotation: 90.0 * Double.pi / 180.0,
            GLLPrefSpaceMouseDeadzoneRotation: 0.0,
            GLLPrefSpaceMouseMode: GLLView.CameraMovementMode.rotateAroundTarget.rawValue,
            GLLPrefControllerCameraRotationSpeed: 30.0 * Double.pi / 180.0,
            GLLPrefControllerCameraMovementSpeed: 1.0,
        ])
    }
    
    @IBAction func openPreferences(sender: Any?) {
        if (preferencesWindowController == nil) {
            preferencesWindowController = GLLPreferencesWindowController()
        }
        
        preferencesWindowController!.showWindow(sender)
    }
}
