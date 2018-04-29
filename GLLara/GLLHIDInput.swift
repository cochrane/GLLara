//
//  GLLHIDInput.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Foundation
import IOKit.hid

// A matcher that matches an incoming change on an HIDElement (with other
// options in the future if we implement Apple's game controllers or similar).
class GLLHIDInput : Hashable, Equatable {
    // Identification for the device
    let deviceVendor: UInt32
    
    // Identification for the manufacturer
    let deviceProduct: UInt32
    
    // Arbitrary value that identifies an element in a device uniquely.
    // (In practice this seems to be a simple integer, where the first element has 1, the second 2 and so on, but of course we won't rely on that)
    let elementCookie: UInt32
    
    // Initializer for creating new one based on an HID value change. If
    // requireUniquePart is set, then nil is returned for values that do not
    // identify one part, e.g. ones in the deadzone or diagonal ones for
    // hatswitches.
    convenience init?(value: IOHIDValue, requireUniquePart: Bool = false) {
        let element = IOHIDValueGetElement(value)
        if (requireUniquePart) {
            if IOHIDElementGetUsagePage(element) == kHIDPage_GenericDesktop
                && IOHIDElementGetUsage(element) == kHIDUsage_GD_Hatswitch {
                // Special casing for hatswitch
                let intValue = IOHIDValueGetIntegerValue(value)
                let logicalMin = IOHIDElementGetLogicalMin(element)
                let offset = intValue - logicalMin
                if offset != 0 && offset != 2 && offset != 4 && offset != 6 {
                    // Diagonal or nothing selected
                    return nil
                }
            } else if GLLHIDInput.isAxis(element: element) {
                // Determine whether upper or lower part
                let intValue = IOHIDValueGetIntegerValue(value)
                let logicalMin = IOHIDElementGetLogicalMin(element)
                let logicalMax = IOHIDElementGetLogicalMax(element)
                
                let mid = (logicalMin + logicalMax) / 2
                if abs(intValue - mid) < ((logicalMax - logicalMin) / 10) {
                    // movement in dead zone
                    return nil
                }
            }
        }
        
        self.init(element: element)
    }
    
    // Simply initializes with an element
    init(element: IOHIDElement) {
        elementCookie = IOHIDElementGetCookie(element)
        
        let device = IOHIDElementGetDevice(element)
        
        var vendorID : Int = 0
        CFNumberGetValue(IOHIDDeviceGetProperty(device, "VendorID" as CFString) as! CFNumber, .intType, &vendorID)
        deviceVendor = UInt32(vendorID)
        
        var productID : Int = 0
        CFNumberGetValue(IOHIDDeviceGetProperty(device, "ProductID" as CFString) as! CFNumber, .intType, &productID)
        deviceProduct = UInt32(productID)
    }
    
    // Parts that an input can have. See partValues for more discussion.
    enum Part {
        case full
        case upper
        case lower
        case hatswitchUp
        case hatswitchRight
        case hatswitchDown
        case hatswitchLeft
    }
    
    // Interpret the values for the various parts of this input.
    // For buttons, this returns only .full
    // For Hatswitches, it returns all the .hatswitchX values.
    // For an axis, it returns .upper, .lower and also .full, the latter for
    // gamepads where each trigger is represented as its own axis. There's no
    // way to detect this so this is something the user must be able to choose.
    func partValues(for value: IOHIDValue) -> [Part: Double] {
        let element = IOHIDValueGetElement(value)
        let intValue = IOHIDValueGetIntegerValue(value)
        let logicalMin = IOHIDElementGetLogicalMin(element)
        let logicalMax = IOHIDElementGetLogicalMax(element)
        if IOHIDElementGetUsagePage(element) == kHIDPage_GenericDesktop
            && IOHIDElementGetUsage(element) == kHIDUsage_GD_Hatswitch {
            // Special casing for hatswitch
            let intValue = IOHIDValueGetIntegerValue(value)
            let logicalMin = IOHIDElementGetLogicalMin(element)
            let offset = intValue - logicalMin
            var result: [Part: Double] = [.hatswitchUp: 0.0, .hatswitchRight: 0.0, .hatswitchDown: 0.0, .hatswitchLeft: 0.0]
            
            if offset == 0 || offset == 1 || offset == 7 {
                result[.hatswitchUp] = 1
            }
            if offset == 1 || offset == 2 || offset == 3 {
                result[.hatswitchRight] = 1
            }
            if offset == 3 || offset == 4 || offset == 5 {
                result[.hatswitchDown] = 1
            }
            if offset == 5 || offset == 6 || offset == 7 {
                result[.hatswitchLeft] = 1
            }
            
            return result
        } else if GLLHIDInput.isAxis(element: element) {
            // Determine whether upper or lower part
            let intValue = IOHIDValueGetIntegerValue(value)
            let logicalMin = IOHIDElementGetLogicalMin(element)
            let logicalMax = IOHIDElementGetLogicalMax(element)
            
            let mid = (logicalMin + logicalMax) / 2
            let lowerRangeEnd = mid - mid/10
            let upperRangeStart = mid + mid/10
            let fullValue = Double(intValue - logicalMin) / Double(logicalMax - logicalMin)
            if intValue < lowerRangeEnd {
                return [.lower: Double(lowerRangeEnd - intValue) / Double(lowerRangeEnd - logicalMin), .upper: 0.0, .full: fullValue]
            } else if intValue > upperRangeStart {
                return [.lower: 0.0, .upper: Double(intValue - upperRangeStart) / Double(logicalMax - upperRangeStart), .full: fullValue]
            } else {
                return [.lower: 0.0, .upper: 0.0, .full: fullValue]
            }
        } else {
            // Normal element
            return [.full: Double(intValue - logicalMin) / Double(logicalMax - logicalMin)]
        }
    }
    
    // Internal: Heuristics to determine if an element represents an axis, with
    // 0 in the middle, as opposed to a 0-1 element or hatswitch.
    private static func isAxis(element: IOHIDElement) -> Bool {
        if IOHIDElementGetType(element) == kIOHIDElementTypeInput_Axis {
            // That would be nice, but never happens
            return true
        }
        let usagePage = IOHIDElementGetUsagePage(element)
        if usagePage != kHIDPage_GenericDesktop {
            // Exclude unknowns but in particular buttons (buttons can have
            // a range of values, too)
            return false
        }
        let usage = IOHIDElementGetUsage(element)
        if usage == kHIDUsage_GD_Hatswitch {
            // Just to be on the safe side
            return false
        }
        let logicalMin = IOHIDElementGetLogicalMin(element)
        let logicalMax = IOHIDElementGetLogicalMax(element)
        if (logicalMax - logicalMin > 1) {
            // This is just a guess
            return true
        }
        return false
    }
    
    public static func == (lhs: GLLHIDInput, rhs: GLLHIDInput) -> Bool {
        return lhs.deviceVendor == rhs.deviceVendor
            && lhs.deviceProduct == rhs.deviceProduct
            && lhs.elementCookie == rhs.elementCookie
    }
    
    public var hashValue: Int {
        var result = 0
        result = result * 31 + Int(deviceVendor)
        result = result * 31 + Int(deviceProduct)
        result = result * 31 + Int(elementCookie)
        return result;
    }
    
    // User visible-name for a part in this thing.
    func name(for part: Part, manager:IOHIDManager) -> String {
        switch part {
        case .full: return name(manager:manager)
        case .lower: return name(manager:manager) + "-"
        case .upper: return name(manager:manager) + "+"
        case .hatswitchUp: return name(manager:manager) + " Up"
        case .hatswitchRight: return name(manager:manager) + " Right"
        case .hatswitchDown: return name(manager:manager) + " Down"
        case .hatswitchLeft: return name(manager:manager) + " Left"
        }
    }
    
    // User-visible name. Needs manager to find actual element again.
    func name(manager: IOHIDManager) -> String {
        // Find the device object
        let devices = IOHIDManagerCopyDevices(manager) as! Set<IOHIDDevice>
        if let device = devices.first(where: {
            var vendorID : Int = 0
            CFNumberGetValue(IOHIDDeviceGetProperty($0, "VendorID" as CFString) as! CFNumber, .intType, &vendorID)
            if (UInt32(vendorID) != self.deviceVendor) {
                return false
            }
            
            var productID : Int = 0
            CFNumberGetValue(IOHIDDeviceGetProperty($0, "ProductID" as CFString) as! CFNumber, .intType, &productID)
            if (UInt32(productID) != self.deviceProduct) {
                return false
            }
            
            return true
        }) {
            if let matchingElements = IOHIDDeviceCopyMatchingElements(device, ["ElementCookie": self.elementCookie] as CFDictionary, 0) as? [IOHIDElement], matchingElements.count > 0 {
                let element = matchingElements[0]
                let page = Int(IOHIDElementGetUsagePage(element))
                let usage = Int(IOHIDElementGetUsage(element))
                switch (page) {
                case kHIDPage_GenericDesktop:
                    if let value = GLLHIDInput.genericDesktopElementName(usage: usage) {
                        return value;
                    }
                    break;
                case kHIDPage_KeyboardOrKeypad:
                    if let value = GLLHIDInput.keyboardOrKeypadUsage(usage: usage) {
                        return value;
                    }
                    break;
                case kHIDPage_Button:
                    return "Button \(usage)"
                case kHIDPage_Consumer:
                    if let value = GLLHIDInput.consumerUsage(usage: usage) {
                        return value;
                    }
                    break;
                default: break
                }
            }
        }
        
        return "\(self.deviceVendor):\(self.deviceProduct) - \(self.elementCookie)"
    }
    
    // Private only: Name for an element in the generic desktop page, if known.
    static private func genericDesktopElementName(usage: Int) -> String? {
        switch (usage) {
        case kHIDUsage_GD_X: return "X Axis"
        case kHIDUsage_GD_Y: return "Y Axis"
        case kHIDUsage_GD_Z: return "Z Axis"
        case kHIDUsage_GD_Rx: return "Rotation X Axis"
        case kHIDUsage_GD_Ry: return "Rotation Y Axis"
        case kHIDUsage_GD_Rz: return "Rotation Z Axis"
        case kHIDUsage_GD_Hatswitch: return "Hatswitch"
        case kHIDUsage_GD_DPadUp: return "DPad up"
        case kHIDUsage_GD_DPadDown: return "DPad down"
        case kHIDUsage_GD_DPadRight: return "DPad right"
        case kHIDUsage_GD_DPadLeft: return "DPad left"
        case kHIDUsage_GD_Wheel: return "Wheel"
        default: return nil
        }
    }
    
    // Private only: Name for an element in the keyboard/keypad page, if known.
    static private func keyboardOrKeypadUsage(usage: Int) -> String? {
        switch (usage) {
        case kHIDUsage_KeyboardA...kHIDUsage_KeyboardZ:
            let capitalA : Unicode.Scalar = "A"
            return "Key " + Unicode.Scalar(capitalA.value + UInt32(usage - kHIDUsage_KeyboardA))!.description
        case kHIDUsage_Keyboard1...kHIDUsage_Keyboard9:
            let one : Unicode.Scalar = "1"
            return "Key " + Unicode.Scalar(one.value + UInt32(usage - kHIDUsage_Keyboard1))!.description
        case kHIDUsage_Keyboard0: return "Key 0" // Separate because it comes after 1-9 in HID usage tables
        case kHIDUsage_KeyboardReturnOrEnter: return "Key Enter"
        case kHIDUsage_KeyboardEscape: return "Key Escape"
        case kHIDUsage_KeyboardDeleteOrBackspace: return "Key Backspace"
        case kHIDUsage_KeyboardTab: return "Key Tab"
        case kHIDUsage_KeyboardSpacebar: return "Key Space"
        default: return nil
        }
    }
    
    // Private only: Name for an element in the consumer page, if known.
    static private func consumerUsage(usage: Int) -> String? {
        switch (usage) {
        case kHIDUsage_Csmr_ACHome: return "Home" // On SteelSeries and similar actually "pause"
        default: return nil
        }
    }
}
