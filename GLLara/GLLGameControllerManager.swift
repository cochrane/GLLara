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
    
    static let shared = GLLGameControllerManager()
    
    init() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidBecomeCurrent, object: nil, queue: nil) { notification in
            if let controller = notification.object as? GCController, let gamepad =  controller.extendedGamepad {
                gamepad.valueChangedHandler = { gamepad, changedElement in
                    if let view = GLLView.lastActiveView {
                        view.gamepadChanged(gamepad: gamepad, element: changedElement)
                    }
                }
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidStopBeingCurrent, object: nil, queue: nil) { notification in
            if let controller = notification.object as? GCController, let gamepad =  controller.extendedGamepad {
                gamepad.valueChangedHandler = nil
            }
        }
        if let gamepad = GCController.current?.extendedGamepad {
            gamepad.valueChangedHandler = { gamepad, changedElement in
                if let view = GLLView.lastActiveView {
                    view.gamepadChanged(gamepad: gamepad, element: changedElement)
                }
            }
        }
    }
}
