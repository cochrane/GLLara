//
//  GLLHIDMode.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Foundation

// A mode is a named set of actions. Only one mode can be active at a given
// time, and only actions belonging to that mode are called.
class GLLHIDMode {
    let name : String
    let actions : [GLLHIDAction]
    
    init(name : String, actions: [GLLHIDAction]) {
        self.name = name
        self.actions = actions
    }
}
