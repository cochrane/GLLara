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
@objc class GLLShaderDescription: NSObject {
    @objc var name: String
    @objc var parameters: GLLModelParams
    
    /*
     * Names of the shaders to be used.
     */

    @objc var vertexName: String?
    @objc var geometryName: String?
    @objc var fragmentName: String?
    
    /*
     * Names of uniforms, in the order that they are specified by models.
     * For each mesh, textures are just specified one after the other, with no information what those textures do. Similarly, with the generic_item format, the settings for the uniforms are specified one after the other, with no information what they do. These arrays give the uniform name for the corresponding index.
     */
    @objc var parameterUniformNames: [String]
    @objc var textureUniformNames: [String]
    
    /*
     * Defines that get passed to the shader compiler.
     */
    @objc var defines: [String: String]
    
    /*
     * Uniforms that are not specified by models.
     */
    @objc var additionalUniformNames: [String]
    
    @objc var allUniformNames: [String] {
        var result = Array<String>(parameterUniformNames)
        result.append(contentsOf: additionalUniformNames)
        return result
    }
    
    @objc var solidMeshGroups: Set<String>
    @objc var alphaMeshGroups: Set<String>
    
    @objc var programIdentifier: String
    
    @objc var localizedName: String {
        return Bundle.main.localizedString(forKey: self.name, value: nil, table: "Shaders")
    }
    
    @objc func description(forParameter parameterName: String) -> GLLRenderParameterDescription {
        return parameters.description(forParameter: parameterName)
    }
    
    @objc func description(forTexture textureUniformName: String) -> GLLTextureDescription {
        return parameters.description(forTexture: textureUniformName)
    }
    
    @objc init(withPlist dictionary: [String: Any], name: String, modelParameters: GLLModelParams) {
        self.name = name
        self.parameters = modelParameters
        
        self.vertexName = dictionary["vertex"] as? String
        self.geometryName = dictionary["geometry"] as? String
        self.fragmentName = dictionary["fragment"] as? String
        
        var flattened: [String] = []
        if let parameters = dictionary["parameters"] as? [Any] {
            for item in parameters {
                if let subParameters = item as? [String] {
                    flattened.append(contentsOf: subParameters)
                } else {
                    flattened.append(item as! String)
                }
            }
        }
        self.parameterUniformNames = flattened
        
        self.textureUniformNames = dictionary["textures"] as? [String] ?? []
        self.additionalUniformNames = dictionary["additionalParameters"] as? [String] ?? []
        self.defines = dictionary["defines"] as? [String:String] ?? [:]
        
        self.alphaMeshGroups = Set<String>(dictionary["alphaMeshGroups"] as? [String] ?? [])
        self.solidMeshGroups = Set<String>(dictionary["solidMeshGroups"] as? [String] ?? [])
        
        self.programIdentifier = name
    }
}
