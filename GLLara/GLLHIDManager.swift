//
//  GLLHIDManager.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Foundation
import IOKit.hid

@objc class GLLHIDManager: NSObject {
    let modes : [GLLHIDMode]
    let hidManager : IOHIDManager
    
    override init() {
        modes = []
        
        // Dynamic: Create the HID manager
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        super.init()
        
        let supportedDevices = [
            ["DeviceUsagePage": kHIDPage_GenericDesktop, "DeviceUsage": kHIDUsage_GD_Joystick],
            ["DeviceUsagePage": kHIDPage_GenericDesktop, "DeviceUsage": kHIDUsage_GD_GamePad],
            ["DeviceUsagePage": kHIDPage_GenericDesktop, "DeviceUsage": kHIDUsage_GD_MultiAxisController],
        ]
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, supportedDevices as CFArray)
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        let unmanaged = Unmanaged.passRetained(self)
        IOHIDManagerRegisterInputValueCallback(hidManager, { context, result, sender, value in
            let myself = Unmanaged<GLLHIDManager>.fromOpaque(context!)
            myself.takeUnretainedValue().received(value: value)
            }, unmanaged.toOpaque());
        IOHIDManagerOpen(hidManager, 0)
    }
    
    deinit {
        IOHIDManagerClose(hidManager, 0)
    }
    
    private func received(value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        if IOHIDElementGetUsagePage(element) >= kHIDPage_VendorDefinedStart {
            // Who knows what's going on there
            return
        }
        
        let input = GLLHIDInput(value: value, requireUniquePart: false)
        print("input", input!.name(manager: hidManager), "values", input!.partValues(for: value), "raw", IOHIDValueGetIntegerValue(value))
    }
}
