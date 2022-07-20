//
//  GLLShaderDataObserver.swift
//  GLLara
//
//  Created by Torsten Kammer on 19.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Combine

@objc class GLLItemMeshShaderObserver: NSObject {
    @objc dynamic var mesh: GLLItemMesh? {
        didSet {
            observations.removeAll()
            updateModules()
            if let mesh = mesh {
                observations.append(mesh.observe(\.shaderModules, options: [ .prior ]) { [weak self] _,_ in
                    if let root = self?.root {
                        root.update()
                    }
                })
                observations.append(mesh.observe(\.shaderBase, options: [ .new ]) { [weak self] _,_ in
                    self?.updateModules()
                })
            }
        }
    }
    private var observations: [NSKeyValueObservation] = []
    
    @objc dynamic var root: GLLShaderModuleObserver
    
    @objc init(mesh: GLLItemMesh?) {
        self.mesh = mesh
        root = GLLItemMeshShaderObserver.buildTree(module: mesh?.shader?.base, mesh: mesh)
        
        super.init()
    }
    
    private func updateModules() {
        root = GLLItemMeshShaderObserver.buildTree(module: mesh?.shader?.base, mesh: mesh)
    }
    
    private static func buildTree(module: GLLShaderModule?, mesh: GLLItemMesh?) -> GLLShaderModuleObserver {
        let vertexSemantics = (mesh?.mesh.vertexDataAccessors?.accessors.map { $0.attribute.semantic }) ?? []
        let childArray: [GLLShaderModule] = module?.children ?? []
        let childObservers = childArray.filter { child in
            return child.matches(vertexAttributes: vertexSemantics)
        }.map { buildTree(module: $0, mesh: mesh) }
        return GLLShaderModuleObserver(mesh: mesh, module: module, children: childObservers)
    }
}

@objc class GLLShaderModuleObserver: NSObject {
    let mesh: GLLItemMesh?
    let module: GLLShaderModule?
    @objc var children: [GLLShaderModuleObserver]
    
    init(mesh: GLLItemMesh?, module: GLLShaderModule?, children: [GLLShaderModuleObserver] = []) {
        self.mesh = mesh
        self.module = module
        self.children = children
    }
    
    func update() {
        willChangeValue(forKey: "included")
        for child in children {
            child.update()
        }
        didChangeValue(forKey: "included")
    }
    
    @objc var name: String {
        return module?.localizedTitle ?? ""
    }
     
    @objc var isIncluded: Bool {
        get {
            return mesh?.isShaderModuleIncluded(module?.name ?? "") ?? false
        }
        set {
            mesh?.setIncluded(newValue, forShaderModule: module?.name ?? "")
            if !newValue {
                for child in children {
                    child.isIncluded = false
                }
            }
        }
    }
}

