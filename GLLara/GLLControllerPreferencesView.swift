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
    
    @ObservedObject var gameControllerManager = GLLCameControllerManager.shared
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
                    
                    Toggle("Invert X-Axis", isOn: $invertXAxis)
                    Toggle("Invert Y-Axis", isOn: $invertYAxis)
                    
                    HStack {
                        if discoveringWirelessControllers {
                            Button("Cancel connecting", action: {
                                GCController.stopWirelessControllerDiscovery()
                            })
                            ProgressView()
                        } else {
                            Button("Connect wireless controller", action: {
                                discoveringWirelessControllers = true
                                GCController.startWirelessControllerDiscovery {
                                    discoveringWirelessControllers = false
                                }
                            })
                        }
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
                        HStack {
                            Text("Speed:").frame(width: 100, height: nil, alignment: .trailing)
                            
                            Slider(value: $speedTranslation, in: 0 ... 3)
                                .onChange(of: speedTranslation) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: GLLPrefSpaceMouseSpeedTranslation)
                                }
                            
                            Text("\(speedTranslation, specifier: "%.1f") unit/s").frame(width: 75, height: nil, alignment: .leading)
                        }
                        HStack {
                            Text("Dead zone:").frame(width: 100, height: nil, alignment: .trailing)
                            
                            Slider(value: $deadZoneTranslation, in: 0 ... 1)
                                .onChange(of: deadZoneTranslation) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: GLLPrefSpaceMouseDeadzoneTranslation)
                                }
                            
                            Text("\(Int(deadZoneTranslation * 100)) %").frame(width: 75, height: nil, alignment: .leading)
                        }
                    }
                    GroupBox("Rotation") {
                        HStack {
                            Text("Speed:").frame(width: 100, height: nil, alignment: .trailing)
                            
                            Slider(value: $speedRotation, in: 0 ... 360.0*Double.pi/180.0)
                                .onChange(of: speedRotation) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: GLLPrefSpaceMouseSpeedRotation)
                                }
                            
                            Text("\(speedRotation * 180.0 / Double.pi, specifier: "%.0f")°/s").frame(width: 75, height: nil, alignment: .leading)
                        }
                        HStack {
                            Text("Dead zone:").frame(width: 100, height: nil, alignment: .trailing)
                            
                            Slider(value: $deadZoneRotation, in: 0 ... 1)
                                .onChange(of: deadZoneRotation) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: GLLPrefSpaceMouseDeadzoneRotation)
                                }
                            
                            Text("\(Int(deadZoneRotation * 100)) %").frame(width: 75, height: nil, alignment: .leading)
                        }
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
