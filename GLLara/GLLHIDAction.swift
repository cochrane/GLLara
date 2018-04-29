//
//  GLLHIDAction.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Foundation

// An action that can be called
class GLLHIDAction {
    let name : String
    
    var inputs : [GLLHIDInput]
    
    init(name: String) {
        self.name = name
        self.inputs = []
    }
}
