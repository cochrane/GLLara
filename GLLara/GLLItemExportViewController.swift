//
//  GLLItemExportViewController.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLItemExportViewController: NSViewController {
    @objc dynamic var includeTransformations: Bool = false
    @objc dynamic var includeVertexColors: Bool = false
    @objc dynamic var canExportAllData: Bool = false
    
    convenience init() {
        self.init(nibName: "GLLItemExportView", bundle: nil)
    }
}
