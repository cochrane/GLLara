//
//  GLLShaderModulesView.swift
//  GLLara
//
//  Created by Torsten Kammer on 19.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import SwiftUI

struct GLLShaderModuleView: View {
    @Binding var moduleObserver: GLLShaderModuleObserver
    var ancestorDisabled: Bool
    
    var body: some View {
        VStack {
            Toggle(moduleObserver.module.name, isOn: $moduleObserver.isIncluded)
                .disabled(ancestorDisabled)
            ForEach($moduleObserver.children) { child in
                HStack {
                    Spacer(minLength: 20.0)
                    GLLShaderModuleView(moduleObserver: child, ancestorDisabled: ancestorDisabled || !moduleObserver.isIncluded)
                }
            }
        }
    }
}

struct GLLItemMeshShaderView: View {
    @ObservedObject var observer: GLLItemMeshShaderObserver
    
    var body: some View {
        HStack {
            Text("Features:")
            GLLShaderModuleView(moduleObserver: $observer.root, ancestorDisabled: false)
        }
    }
}
