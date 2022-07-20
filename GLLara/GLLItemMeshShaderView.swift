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
        VStack(alignment: .leading) {
            HStack {
                Toggle(moduleObserver.module?.localizedTitle ?? "No name", isOn: $moduleObserver.isIncluded)
                    .disabled(ancestorDisabled)
            }
            ForEach($moduleObserver.children) { child in
                HStack {
                    Spacer().frame(minWidth: 20.0, idealWidth: 20.0, maxWidth: 20.0)
                    GLLShaderModuleView(moduleObserver: child, ancestorDisabled: ancestorDisabled || !moduleObserver.isIncluded)
                }
            }
        }
    }
}

struct GLLItemMeshShaderView: View {
    @StateObject var observer: GLLItemMeshShaderObserver
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach($observer.root.children) { child in
                GLLShaderModuleView(moduleObserver: child, ancestorDisabled: false)
            }
        }
        .padding()
    }
}

@objc class GLLItemMeshShaderViewWrapper: NSObject {
    @objc func createShaderView(itemMesh: GLLItemMesh) -> NSView {
        let observer = GLLItemMeshShaderObserver(item: itemMesh)
        return NSHostingView(rootView: GLLItemMeshShaderView(observer: observer))
    }
}
