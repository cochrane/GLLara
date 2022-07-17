//
//  GLLGameControllerManager.swift
//  GLLara
//
//  Created by Torsten Kammer on 14.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Combine
import GameController

/**
 * Manager that listens to inputs on a 3D or "space" mouse device, if any is
 * connected, and provides its values to the program. They are processed by
 * the GLLView.
 *
 * These devices are rare but fun. It works with classic HID interfaces
 * internally.
 */
class GLLGameControllerManager: ObservableObject {
    
    @Published var knownDevices: [GCController] = []
    
    static let shared = GLLGameControllerManager()
    
    init() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil) { notification in
            if let controller = notification.object as? GCController, let gamepad =  controller.extendedGamepad {
                self.knownDevices.append(controller)
                
                gamepad.valueChangedHandler = { gamepad, changedElement in
                    if let view = GLLView.lastActiveView {
                        view.gamepadChanged(gamepad: gamepad, element: changedElement)
                    }
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: nil) { notification in
            self.knownDevices.removeAll { $0 == notification.object as? GCController }
        }
    }
    
    var firstDeviceName: String? {
        get {
            guard knownDevices.count > 0  else {
                return nil
            }
            return knownDevices[0].vendorName
        }
        set {
            // Does nothing, just here to make this property SwiftUI compatible
        }
    }
}
