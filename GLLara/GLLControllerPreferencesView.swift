//
//  GLLControllerPreferencesView.swift
//  GLLara
//
//  Created by Torsten Kammer on 13.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import SwiftUI
import Cocoa
import GameController

fileprivate struct ControllerPreferencesSlider: View {
    
    @State var value: Double
    
    let range: ClosedRange<Double>
    let preferenceKey: String
    let label: LocalizedStringKey
    let valueDescription: (Double) -> LocalizedStringKey
    
    init(for preferenceKey: String, in range: ClosedRange<Double>,  label: LocalizedStringKey, valueDescription: @escaping (Double) -> LocalizedStringKey) {
        self.range = range
        self.value = UserDefaults.standard.double(forKey: preferenceKey)
        self.preferenceKey = preferenceKey
        self.label = label
        self.valueDescription = valueDescription
    }
    
    var body: some View {
        HStack {
            Text(label).frame(width: 100, height: nil, alignment: .trailing)
            
            Slider(value: $value, in: range)
                .onChange(of: value) { newValue in
                    UserDefaults.standard.set(newValue, forKey: preferenceKey)
                }
            
            Text(valueDescription(value)).frame(width: 75, height: nil, alignment: .leading)
        }

    }
}

struct GLLControllerPreferencesView: View {
    // Mode is not set here, that is something the user can adjust on the fly using the buttons (eventually)
    // Note: Going via @state and explicit update instead of @appstorage because otherwise the labels on the sliders don't work
    @State var speedTranslation: Double = UserDefaults.standard.double(forKey: GLLPrefSpaceMouseSpeedTranslation)
    @State var speedRotation: Double = UserDefaults.standard.double(forKey: GLLPrefSpaceMouseSpeedRotation)
    @State var deadZoneTranslation: Double = UserDefaults.standard.double(forKey: GLLPrefSpaceMouseDeadzoneTranslation)
    @State var deadZoneRotation: Double = UserDefaults.standard.double(forKey: GLLPrefSpaceMouseDeadzoneRotation)
    
    @AppStorage(GLLPrefControllerInvertXAxis) var invertXAxis = false
    @AppStorage(GLLPrefControllerInvertYAxis) var invertYAxis = false
    
    @State var discoveringWirelessControllers = false
    
    @ObservedObject var gameControllerManager = GLLGameControllerManager.shared
    @ObservedObject var spaceMouseManager = GLLSpaceMouseManager.shared
    
    var body: some View {
        VStack {
            
            GroupBox("Game controller") {
                VStack(alignment: .leading) {
                    if gameControllerManager.firstDeviceName != nil {
                        Text("Connected: \(gameControllerManager.firstDeviceName!)")
                    } else {
                        Text("No game controller connected")
                    }
                    
                    GroupBox("Camera") {
                        Toggle("Invert X-Axis", isOn: $invertXAxis)
                        Toggle("Invert Y-Axis", isOn: $invertYAxis)
                        
                        ControllerPreferencesSlider(for: GLLPrefControllerCameraMovementSpeed, in : 0 ... 3, label: "Movement:", valueDescription: { value in
                            "\(value, specifier: "%.1f") unit/s"
                        })
                        ControllerPreferencesSlider(for: GLLPrefControllerCameraRotationSpeed, in : 0 ... 360.0*Double.pi/180.0, label: "Rotation:", valueDescription: { value in
                            "\(speedRotation * 180.0 / Double.pi, specifier: "%.0f")°/s"
                        })
                    }
                }
            }
            
            GroupBox("3D Mouse") {
                VStack(alignment: .leading) {
                    if spaceMouseManager.firstDeviceName != nil {
                        Text("Connected: \(spaceMouseManager.firstDeviceName!)")
                    } else {
                        Text("No 3D mouse connected")
                    }
                    GroupBox("Movement") {
                        ControllerPreferencesSlider(for: GLLPrefSpaceMouseSpeedTranslation, in : 0 ... 3, label: "Speed:", valueDescription: { value in
                            "\(value, specifier: "%.1f") unit/s"
                        })
                        ControllerPreferencesSlider(for: GLLPrefSpaceMouseDeadzoneTranslation, in : 0 ... 1, label: "Dead zone:", valueDescription: { value in
                            "\(Int(value * 100)) %"
                        })
                    }
                    GroupBox("Rotation") {
                        ControllerPreferencesSlider(for: GLLPrefSpaceMouseSpeedRotation, in : 0 ... 360.0*Double.pi/180.0, label: "Speed:", valueDescription: { value in
                            "\(speedRotation * 180.0 / Double.pi, specifier: "%.0f")°/s"
                        })
                        ControllerPreferencesSlider(for: GLLPrefSpaceMouseDeadzoneRotation, in : 0 ... 1, label: "Dead zone:", valueDescription: { value in
                            "\(Int(value * 100)) %"
                        })
                    }
                }.padding()
            }
            .padding()
        }
    }
}

// That name may have been a mistake.
@objc class GLLControllerPreferencesViewController: NSViewController {
    
    override func loadView() {
        let myView = NSHostingView(rootView: GLLControllerPreferencesView())
        self.view = myView
    }
}

struct GLLControllerPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        GLLControllerPreferencesView()
    }
}
