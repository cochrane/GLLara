//
//  GLLShaderDataObserver.swift
//  GLLara
//
//  Created by Torsten Kammer on 19.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Combine

class GLLItemMeshShaderObserver: ObservableObject {
    private let item: GLLItemMesh
    private var observations: [NSKeyValueObservation] = []
    
    @Published var root: GLLShaderModuleObserver
    
    init(item: GLLItemMesh) {
        self.item = item
        root = GLLItemMeshShaderObserver.buildTree(module: item.shader?.base, item: item)
        observations.append(item.observe(\.shaderModules, options: [ .prior ]) { [weak self] _,_ in
            if let root = self?.root {
                root.update()
            }
        })
        observations.append(item.observe(\.shaderBase, options: [ .new ]) { [weak self] _,_ in
            self?.updateModules()
        })
    }
    
    private func updateModules() {
        root = GLLItemMeshShaderObserver.buildTree(module: item.shader.base, item: item)
    }
    
    private static func buildTree(module: GLLShaderModule?, item: GLLItemMesh) -> GLLShaderModuleObserver {
        let vertexSemantics = (item.mesh.vertexDataAccessors?.accessors.map { $0.attribute.semantic }) ?? []
        let childArray: [GLLShaderModule] = module?.children ?? []
        let childObservers = childArray.filter { child in
            return child.matches(vertexAttributes: vertexSemantics)
        }.map { buildTree(module: $0, item: item) }
        return GLLShaderModuleObserver(item: item, module: module, children: childObservers)
    }
}

class GLLShaderModuleObserver: ObservableObject, Identifiable {
    let item: GLLItemMesh
    let module: GLLShaderModule?
    @Published var children: [GLLShaderModuleObserver]
    
    init(item: GLLItemMesh, module: GLLShaderModule?, children: [GLLShaderModuleObserver] = []) {
        self.item = item
        self.module = module
        self.children = children
    }
    
    func update() {
        objectWillChange.send()
        for child in children {
            child.update()
        }
    }
    
    var isIncluded: Bool {
        get {
            return item.isShaderModuleIncluded(module?.name ?? "")
        }
        set {
            item.setIncluded(newValue, forShaderModule: module?.name ?? "")
            if !newValue {
                for child in children {
                    child.isIncluded = false
                }
            }
        }
    }
}

