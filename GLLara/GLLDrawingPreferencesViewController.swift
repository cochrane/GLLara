//
//  GLLDrawingPreferencesViewController.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLDrawingPreferencesViewController: NSViewController {
    
    convenience init() {
        self.init(nibName: "GLLDrawingPreferencesView", bundle: nil)
    }
    
    @objc dynamic var maxAnisotropyLevel: Int {
        return GLLResourceManager.shared.maxAnisotropyLevel
    }
}
