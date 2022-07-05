//
//  GLLShaderDescription.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation
import Combine

extension GLLFunctionConstant: Decodable {
    
}

/**
 * A set of inputs for a shader, and associated compile-time defines. Several of these get combined with a base shader (which also inherits from this).
 */
@objc class GLLShaderModule: NSObject, Decodable {
    // The name of the module. Must be unique among its parents; should be unique in general. The user-facing version is found via localized string
    @objc let name: String
    
    // The names of the bound textures that this shader requires
    let textureUniforms: [String]?
    
    // Other uniforms, either colors or floats, that the user or model can/should provide.
    let parameterUniforms: [String]?
    
    // The preprocessor defines that get used to actually change what the shader does
    let activeBoolConstants: [GLLFunctionConstant]?
    
    // The vertex attributes that must be present in order for this module to be usable.
    let requiredVertexAttributes: [String]?
    
    // Other modules that can be activated. If any of them are activated, then this must be activated as well.
    let children: [GLLShaderModule]?
    
    init(name: String, textureUniforms: [String]? = nil, parameterUniforms: [String]? = nil, requiredVertexAttributes: [String]? = nil, activeBoolConstants: [GLLFunctionConstant]? = nil, children: [GLLShaderModule]? = nil) {
        self.name = name
        self.textureUniforms = textureUniforms
        self.parameterUniforms = parameterUniforms
        self.requiredVertexAttributes = requiredVertexAttributes
        self.activeBoolConstants = activeBoolConstants
        self.children = children
    }
    
    private func vertexAttributeEnum(for name: String) -> GLLVertexAttribSemantic? {
        switch (name) {
        case "normal":
            return .normal
        case "vertexColor":
            return .color
        case "boneIndices":
            return .boneIndices
        case "boneWeights":
            return .boneWeights
        case "tangents":
            return .tangent0
        case "texCoord1":
            return .texCoord0 // TODO Obviously bullshit, will need to rework this
        default:
            return nil
        }
    }
    
    var requiredVertexAttribEnums: [GLLVertexAttribSemantic]? {
        return requiredVertexAttributes?.map {
            vertexAttributeEnum(for: $0)!
        }
    }
    
    func matches(textures: [String], vertexAttributes: [GLLVertexAttribSemantic]) -> Bool {
        if let textureUniforms = textureUniforms,  !textureUniforms.allSatisfy({ textures.contains($0) }) {
            return false
        }
        if let myVertexAttributes = requiredVertexAttribEnums, !myVertexAttributes.allSatisfy({ vertexAttributes.contains($0) }) {
            return false
        }
        
        // Do not use items that are purely additional or only require render parameters
        if textureUniforms == nil && requiredVertexAttributes == nil {
            return false
        }
        
        return true
    }
    
    func descendantsMatching(textures: [String], vertexAttributes: [GLLVertexAttribSemantic]) -> [GLLShaderModule] {
        var descendants: [GLLShaderModule] = []
        if let children = children {
            for child in children {
                if (child.matches(textures: textures, vertexAttributes: vertexAttributes)) {
                    descendants.append(child);
                    descendants.append(contentsOf: child.descendantsMatching(textures: textures, vertexAttributes: vertexAttributes))
                }
            }
        }
        return descendants
    }
    
    func allModules(forNames names: [String]) -> [GLLShaderModule] {
        var descendants: [GLLShaderModule] = []
        if let children = children {
            for child in children {
                let childModules = child.allModules(forNames: names)
                if names.contains(child.name) || childModules.count > 0 {
                    descendants.append(child)
                    descendants.append(contentsOf: childModules)
                }
            }
        }
        return descendants
    }
    
    override var debugDescription: String {
        return super.debugDescription + " - " + self.name
    }
}

/**
 * Base for any shader hierarchy, defining the files that are actually used.
 */
@objc class GLLShaderBase: GLLShaderModule {
    /// Name of the vertex shader to use
    let vertex: String?
    /// Name of the fragment shader to use
    let fragment: String?
    /**
     * Format strings that describes what the output tex coord attribute is
     * named for a given tex coord set. E.g. if this is outTexCoord%ld then
     * the output tex coordinate will be named outTexCoord0 for tex coord set 0.
     *
     * This is used together with texCoordDefineFormat; look there for details.
     */
    @objc let texCoordVarNameFormat: String
    
    /**
     * Format string that defines what name to use for the tex coords for a
     * given texture. Used together with texCoordFragmentNameFormat.
     *
     * The idea here is that if, say, "diffuse" is assigned tex set coord 0,
     * "normal" is assigned tex coord set 0, and "lightmap" is assigned tex
     * coord set 1, the shader loader can generate the defines:
     *
     *     #define diffuseTexCoord outTexCoord0
     *     #define normalTexCoord outTexCoord0
     *     #define lightmapTexCoord outTexCoord1
     *
     * The texCoordDefineFormat gives the left side of this assignment; the
     * texCoordVarNameFormat gives the right side of this.
     */
    @objc let texCoordDefineFormat: String
    
    enum CodingKeys: CodingKey {
        case vertex
        case fragment
        case texCoordVarNameFormat
        case texCoordDefineFormat
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        vertex = try container.decodeIfPresent(String.self, forKey: .vertex)
        fragment = try container.decodeIfPresent(String.self, forKey: .fragment)
        
        texCoordVarNameFormat = try container.decodeIfPresent(String.self, forKey: .texCoordVarNameFormat) ?? "outTexCoord%ld"
        texCoordDefineFormat = try container.decodeIfPresent(String.self, forKey: .texCoordDefineFormat) ?? "%@Coord"
        
        try super.init(from: decoder)
    }
    
    init(name: String, vertex: String? = nil, fragment: String? = nil, textureUniforms: [String]? = nil, parameterUniforms: [String]? = nil, requiredVertexAttributes: [String]? = nil, children: [GLLShaderModule]? = nil) {
        self.vertex = vertex
        self.fragment = fragment
        self.texCoordVarNameFormat = ""
        self.texCoordDefineFormat = ""
        super.init(name: name, textureUniforms: textureUniforms, parameterUniforms: parameterUniforms, requiredVertexAttributes: requiredVertexAttributes, children: children)
    }
}

@objc class GLLShaderData: NSObject, NSCopying {
    @objc let base: GLLShaderBase
    @objc let activeModules: [GLLShaderModule]
    @objc let texCoordAssignments: [String: Int]
    @objc let alphaBlending: Bool
    let parameters: GLLModelParams
    
    init(base: GLLShaderBase, activeModules: [GLLShaderModule], texCoordAssignments: [String: Int] = [:], alphaBlending: Bool, parameters: GLLModelParams) {
        self.base = base
        
        let activeModuleSet = Set(activeModules)
        
        self.activeModules = activeModuleSet.sorted(by: { $0.name < $1.name })
        self.texCoordAssignments = texCoordAssignments
        self.alphaBlending = alphaBlending
        self.parameters = parameters
    }
    
    @objc lazy var textureUniforms: [String] = {
        var textureUniforms: [String] = base.textureUniforms ?? []
        for module in activeModules {
            textureUniforms.append(contentsOf: module.textureUniforms ?? [])
        }
        return textureUniforms
    }()
    
    @objc lazy var parameterUniforms: [String] = {
        var parameterUniforms: [String] = base.parameterUniforms ?? []
        for module in activeModules {
            parameterUniforms.append(contentsOf: module.parameterUniforms ?? [])
        }
        return parameterUniforms
    }()
    
    @objc var activeBoolConstants: NSIndexSet {
        let set = NSMutableIndexSet()
        for module in activeModules {
            guard let constants = module.activeBoolConstants else {
                continue
            }
            for value in constants {
                set.add(Int(value.rawValue))
            }
        }
        return set
    }
    
    /**
     * The number of the texture coordinate set to use for the texture with the
     * given identifier. This is usually 0.
     */
    @objc func texCoordSet(forTexture textureUniformName: String) -> Int {
        return texCoordAssignments[textureUniformName] ?? 0
    }
    
    @objc func description(forParameter parameterName: String) -> GLLRenderParameterDescription {
        return parameters.description(forParameter: parameterName)
    }
    
    @objc func description(forTexture textureUniformName: String) -> GLLTextureDescription {
        return parameters.description(forTexture: textureUniformName)
    }
    
    @objc var vertexName: String? {
        return base.vertex
    }
    
    @objc var fragmentName: String? {
        return base.fragment
    }
    
    // For easier comparisons
    private lazy var sortedModuleNames: [String] = {
        let set = Set<String>(activeModules.makeIterator().map({ $0.name }))
        return set.sorted()
    }()
    
    override var hash: Int {
        var hasher = Hasher()
        base.name.hash(into: &hasher)
        sortedModuleNames.hash(into: &hasher)
        texCoordAssignments.hash(into: &hasher)
        alphaBlending.hash(into: &hasher)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? GLLShaderData else {
            return false
        }
        return base.name == other.base.name && sortedModuleNames == other.sortedModuleNames && texCoordAssignments == other.texCoordAssignments && alphaBlending == other.alphaBlending && parameters == other.parameters
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

@objc class XnaLaraShaderDescription: NSObject, Decodable {
    @objc let baseName: String
    @objc let moduleNames: [String]
    
    @objc let solidMeshGroups: [String]
    @objc let alphaMeshGroups: [String]
    
    @objc let textureUniformsInOrder: [String]
    @objc let parameterUniformsInOrder: [[String]]
    
    let texCoordSets: [String: Int]
    
    enum CodingKeys: CodingKey {
        case base
        case modules
        case solidMeshGroups
        case alphaMeshGroups
        case textures
        case parameters
        case texCoordSets
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.baseName = try container.decode(String.self, forKey: .base)
        self.moduleNames = try container.decodeIfPresent([String].self, forKey: .modules) ?? []
        self.solidMeshGroups = try container.decodeIfPresent([String].self, forKey: .solidMeshGroups) ?? []
        self.alphaMeshGroups = try container.decodeIfPresent([String].self, forKey: .alphaMeshGroups) ?? []
        self.textureUniformsInOrder = try container.decodeIfPresent([String].self, forKey: .textures) ?? []
        
        var parameterUniforms: [[String]] = []
        if container.contains(.parameters) {
            var parameters = try container.nestedUnkeyedContainer(forKey: .parameters)
            while !parameters.isAtEnd {
                if let array = try? parameters.decodeIfPresent([String].self) {
                    parameterUniforms.append(array)
                } else {
                    let value = try parameters.decode(String.self)
                    parameterUniforms.append([value])
                }
            }
        }
        self.parameterUniformsInOrder = parameterUniforms
        self.texCoordSets = try container.decodeIfPresent([String: Int].self, forKey: .texCoordSets) ?? [:]
    }
    
    @objc func texCoordSet(for texture: String) -> Int {
        return texCoordSets[texture] ?? 0
    }
}
