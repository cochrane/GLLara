//
//  GLLRenderWindow.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLRenderWindow: NSWindow {
    
    @IBOutlet weak var renderView: GLLView?
    
    override func becomeKey() {
        super.becomeKey()
        
        renderView?.windowBecameKey()
    }
    
    override func resignKey() {
        super.resignKey()
        
        renderView?.windowResignedKey()
    }
    
}
