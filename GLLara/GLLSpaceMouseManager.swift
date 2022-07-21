//
//  GLLHIDManager.swift
//  GLLara
//
//  Created by Torsten Kammer on 09.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa
import IOKit.hid
import Combine

/**
 * Manager that listens to inputs on a 3D or "space" mouse device, if any is
 * connected, and provides its values to the program. They are processed by
 * the GLLView.
 *
 * These devices are rare but fun. It works with classic HID interfaces
 * internally.
 */
class GLLSpaceMouseManager: ObservableObject {
    private let hidManager: IOHIDManager
    private let dispatchQueue: DispatchQueue
    
    class DeviceState {
        let device: IOHIDDevice
        var rotation: SIMD3<Float> = SIMD3<Float>(repeating: 0)
        var position: SIMD3<Float> = SIMD3<Float>(repeating: 0)
        
        var logger = Logger()
        
        init(device: IOHIDDevice) {
            self.device = device
            explicitlyUpdateElements()
        }
        
        func explicitlyUpdateElements() {
            // Get values (as many as are available)
            // X-Z and Rx-Rz are directely sequently so can use min and max key
            let matching = [
                kIOHIDElementUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDElementUsageMinKey: kHIDUsage_GD_X,
                kIOHIDElementUsageMaxKey: kHIDUsage_GD_Rz,
            ] as CFDictionary
            let elements = IOHIDDeviceCopyMatchingElements(device, matching as CFDictionary, 0)! as! [IOHIDElement]
                        
            for element in elements {
                let emptyValue = IOHIDValueCreateWithIntegerValue(nil, element, 0, 0)
                var unmanagedValue = Unmanaged.passUnretained(emptyValue)
                let result = IOHIDDeviceGetValue(device, element, &unmanagedValue)
                if result == kIOReturnSuccess {
                    valueChanged(element: element, newValue: emptyValue)
                }
            }
        }
        
        func valueChanged(element: IOHIDElement, newValue: IOHIDValue) {
            guard IOHIDElementGetUsagePage(element) == kHIDPage_GenericDesktop, IOHIDElementGetType(element) != kIOHIDElementTypeCollection else {
                return
            }
            
            let min = IOHIDElementGetLogicalMin(element)
            let max = IOHIDElementGetLogicalMax(element)
            
            let value = IOHIDValueGetIntegerValue(newValue)
            let relativeValue = value >= 0 ? Float(value) / Float(max) : -(Float(value) / Float(min))
            
            switch Int(IOHIDElementGetUsage(element)) {
            case kHIDUsage_GD_X:
                position.x = relativeValue
            case kHIDUsage_GD_Y:
                position.y = relativeValue
            case kHIDUsage_GD_Z:
                position.z = relativeValue
            case kHIDUsage_GD_Rx:
                rotation.x = relativeValue
            case kHIDUsage_GD_Ry:
                rotation.y = relativeValue
            case kHIDUsage_GD_Rz:
                rotation.z = relativeValue
                
            default: break
                // Ignored
            }
        }
        
        lazy var name: String = {
            if let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as! CFString? {
                return name as String
            }
            return "Unknown"
        }()
    }
    
    @Published private var knownDevices: [DeviceState] = []
    
    static let shared = GLLSpaceMouseManager()
    
    init() {
        hidManager = IOHIDManagerCreate(nil, 0)
        dispatchQueue = DispatchQueue(label: "spacemouse-hid", qos: .default, attributes: [])
              
        let deviceMatching = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_MultiAxisController
        ] as CFDictionary
        
        IOHIDManagerSetDeviceMatching(hidManager, deviceMatching)
        
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode!.rawValue)
        
        let context = Unmanaged.passRetained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(hidManager, { context, result, sender, device in
            guard result == kIOReturnSuccess else {
                return
            }
            
            Unmanaged<GLLSpaceMouseManager>.fromOpaque(context!).takeUnretainedValue().deviceAdded(device: device)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(hidManager, { context, result, sender, device in
            guard result == kIOReturnSuccess else {
                return
            }
            
            Unmanaged<GLLSpaceMouseManager>.fromOpaque(context!).takeUnretainedValue().deviceRemoved(device: device)
        }, context)
        IOHIDManagerRegisterInputValueCallback(hidManager, { context, result, sender, value in
            guard result == kIOReturnSuccess else {
                return
            }
            
            let manager = Unmanaged<GLLSpaceMouseManager>.fromOpaque(context!).takeUnretainedValue()
            manager.elementChanged(value: value)
        }, context)
        
        IOHIDManagerOpen(hidManager, 0)
    }
    
    private func elementChanged(value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let device = IOHIDElementGetDevice(element)
        
        if let state = knownDevices.first(where: { $0.device == device }) {
            state.valueChanged(element: element, newValue: value)
            
            if let view = GLLView.lastActiveView {
                view.unpause()
            }
        }
    }
    
    private func deviceAdded(device: IOHIDDevice) {
        knownDevices.append(DeviceState(device: device))
    }
    
    private func deviceRemoved(device: IOHIDDevice) {
        knownDevices.removeAll { $0.device == device }
    }
    
    var firstDeviceName: String? {
        get {
            guard knownDevices.count > 0  else {
                return nil
            }
            return knownDevices[0].name
        }
        set {
            // Does nothing, just here to make this property SwiftUI compatible
        }
    }
    
    var averageRotationAndPosition: (SIMD3<Float>, SIMD3<Float>) {
        var rotation = SIMD3<Float>()
        var position = SIMD3<Float>()
        
        for device in knownDevices {
            rotation += device.rotation
            position += device.position
        }
        return (rotation, position)
    }
}
