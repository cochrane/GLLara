//
//  GLLShaderDescription.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

/*!
 * @abstract Description of a rendering method.
 * @discussion A rendering method always corresponds to one shader, but also
 * stores the inputs to this shader, in particular the render parameters
 * (model-specific uniforms) and textures it expects, and the render group
 * names to which this shader applies.
 */
@objc class GLLShaderDescription: NSObject, Decodable {
    @objc var name: String?
    @objc var parameters: GLLModelParams?
    
    /*
     * Names of the shaders to be used.
     */

    @objc let vertexName: String?
    @objc let geometryName: String?
    @objc let fragmentName: String?
    
    /*
     * Names of uniforms, in the order that they are specified by models.
     * For each mesh, textures are just specified one after the other, with no information what those textures do. Similarly, with the generic_item format, the settings for the uniforms are specified one after the other, with no information what they do. These arrays give the uniform name for the corresponding index.
     */
    @objc let genericMeshUniformMappings: [[String]]
    @objc let textureUniformNames: [String]
    
    /*
     * Defines that get passed to the shader compiler.
     */
    @objc let defines: [String: String]
    
    /*
     * Uniforms that are not specified by XNALara models.
     */
    @objc let allUniformNames: [String]
    
    @objc let solidMeshGroups: Set<String>
    @objc let alphaMeshGroups: Set<String>
    
    @objc var programIdentifier: String {
        return name!
    }
    
    @objc var localizedName: String {
        return Bundle.main.localizedString(forKey: self.name!, value: nil, table: "Shaders")
    }
    
    @objc func description(forParameter parameterName: String) -> GLLRenderParameterDescription {
        return parameters!.description(forParameter: parameterName)
    }
    
    @objc func description(forTexture textureUniformName: String) -> GLLTextureDescription {
        return parameters!.description(forTexture: textureUniformName)
    }
    
    enum PlistCodingKeys: String, CodingKey {
        case vertex, geometry, fragment
        case parameters
        case textures
        case additionalParameters
        case defines
        case alphaMeshGroups
        case solidMeshGroups
    }
    
    required init(from decoder: Decoder) throws {
        self.name = nil
        self.parameters = nil
        
        let container = try decoder.container(keyedBy: PlistCodingKeys.self)
        self.vertexName = try container.decodeIfPresent(String.self, forKey: .vertex)
        self.geometryName = try container.decodeIfPresent(String.self, forKey: .geometry)
        self.fragmentName = try container.decodeIfPresent(String.self, forKey: .fragment)
        
        // I don't remember why we have this
        var uniformNames: [String] = []
        var uniformsForGenericMeshParameters: [[String]] = []
        if container.contains(.parameters) {
            var parameters = try container.nestedUnkeyedContainer(forKey: .parameters)
            while !parameters.isAtEnd {
                if let array = try? parameters.decodeIfPresent([String].self) {
                    uniformNames.append(contentsOf: array)
                    uniformsForGenericMeshParameters.append(array)
                } else {
                    let value = try parameters.decode(String.self)
                    uniformNames.append(value)
                    uniformsForGenericMeshParameters.append([value])
                }
            }
        }
        self.genericMeshUniformMappings = uniformsForGenericMeshParameters
        
        self.textureUniformNames = try container.decodeIfPresent([String].self, forKey: .textures) ?? []
        let freeUniformNames = try container.decodeIfPresent([String].self, forKey: .additionalParameters) ?? []
        uniformNames.append(contentsOf:freeUniformNames)
        self.allUniformNames = uniformNames
        
        self.defines = try container.decodeIfPresent([String:String].self, forKey: .defines) ?? [:]
        
        self.alphaMeshGroups = Set(try container.decodeIfPresent([String].self, forKey: .alphaMeshGroups) ?? [])
        self.solidMeshGroups = Set(try container.decodeIfPresent([String].self, forKey: .solidMeshGroups) ?? [])
    }
}
