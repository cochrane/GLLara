//
//  GLLNoSelectionViewController.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLNoSelectionViewController: NSViewController {
    
    convenience init() {
        self.init(nibName: "GLLNoSelectionView", bundle: nil)
    }
    
    @IBAction override func showContextHelp(_ sender: Any?) {
        let locBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as! NSString?
        NSHelpManager.shared.openHelpAnchor("models", inBook: locBookName as NSHelpManager.BookName?)
    }
}
