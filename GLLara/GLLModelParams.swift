//
//  GLLModelParams.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLMeshParams: NSObject {
    @objc var meshGroups: [String] = []
    @objc var displayName: String = ""
    @objc var visible: Bool = true
    @objc var optionalPartNames: [String] = []
    @objc var shader: GLLShaderDescription? = nil
    @objc var transparent: Bool = false
    @objc var renderParameters: [String: Double] = [:]
    @objc var splitters: [GLLMeshSplitter] = []
    
    var cameraTargetName: String? = nil
    var cameraTargetBones: [String] = []
}

/*!
 * @abstract Encapsulates all the data that is hardcoded into XNALara and stores it in a single place.
 * @discussion Holy fucking shit. XNALara consists basically only of hardcoded values for every damn object you can import. And it's not just hardcoded in one place; there's the item subclasses, but the renderer also contains an awful lot of specific information. That sucks.
 
 * The goal of this class is to take all that information and put it into separate configuration files, where all this shit can be managed in a simple, central location.
 */
@objc class GLLModelParams: NSObject {
    
    @objc static func parameters(forModel model: GLLModel) throws -> GLLModelParams {
        // Check whether it is an XPS file
        let typeIdentifiers = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, model.baseURL.pathExtension as CFString, nil)!.takeRetainedValue() as! [String]
        if typeIdentifiers.contains("com.home-forum.xnalara.xpsmesh") {
            return try GLLModelParams(model: model)
        }
        
        let name = ((model.baseURL.lastPathComponent as NSString).deletingPathExtension as NSString).deletingPathExtension.lowercased()
        if name == "generic_item" || name == "character" || name == "outfit" {
            return try GLLModelParams(model: model)
        }
        
        return try parameters(forName: name)
    }
    
    private static var parametersCache: [String: GLLModelParams] = [:]
    
    @objc static func parameters(forName name: String) throws -> GLLModelParams {
        if let result = parametersCache[name] {
            return result
        }
        
        guard let plistUrl = Bundle.main.url(forResource: name, withExtension: "modelparams.plist") else {
            throw NSError(domain: "GLLModelParams", code: 1, userInfo: [
                NSLocalizedDescriptionKey : String(format:NSLocalizedString("Did not find model parameters for model type %@", comment: "Bundle didn't find Modelparams file."), name),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("GLLara stores special information for files not named generic_item. This information is not available", comment: "Bundle didn't find Modelparams file.")
                          ])
        }
        
        let data = try Data(contentsOf: plistUrl)
        let result = try GLLModelParams(data: data)
        parametersCache[name] = result
        return result
    }
    
    private static let meshNameRegexpString = """
^([0-9P]{1,2})_
([^_\\n]+(?:_[^0-9\\n]+)*)
(?:
_([\\d\\.]+)
(?:
_([\\d\\.]+)
(?:_([\\d\\.]+)
(?:
_([^_\\n]+)
(?:
_([^_\\n]+)
)*
)?
)?
)?
)?_?$
"""
    
    private static let meshNameRegexp = try! NSRegularExpression(pattern:meshNameRegexpString, options: [.allowCommentsAndWhitespace, .anchorsMatchLines])
    
    struct PlistDataTransferObject: Decodable {
        var base: String?
        var meshGroupNames: [String: [String]]?
        // Only float render parameters get values in the plist
        var renderParameters: [String: [String: Double]]?
        var defaultRenderParameters: [String: Double]?
        var cameraTargets: [String: [String]]?
        var defaultMeshGroup: String?
        var meshSplitters: [String : [GLLMeshSplitter]]?
        var shaders: [String: GLLShaderDescription]?
        var renderParameterDescriptions: [String: GLLRenderParameterDescription]?
        var textureDescriptions: [String: GLLTextureDescription]?
        var defaultTextures: [String: String]?
        
        // TODO We seem to have forgotten about renderParameterRemappings somewhere along the line. Where does that go?
    }
    private let model: GLLModel?
    private let plistData: PlistDataTransferObject?
    
    init(data: Data) throws {
        let decoder = PropertyListDecoder()
        plistData = try decoder.decode(PlistDataTransferObject.self, from: data)
        model = nil
        
        if let baseName = plistData!.base {
            self.base = try GLLModelParams.parameters(forName: baseName)
        } else {
            self.base = nil
        }
        
        super.init()
        
        if let shaders = plistData?.shaders {
            for (name, shader) in shaders {
                shader.name = name
                shader.parameters = self
            }
        }
    }
    
    // Generic item format
    init(model: GLLModel) throws {
        self.model = model
        self.base = try GLLModelParams.parameters(forName: "lara")
        self.plistData = nil
    }
    
    var base: GLLModelParams?
    
    @objc func params(forMesh meshName: String) -> GLLMeshParams {
        let params = GLLMeshParams()
        params.displayName = meshName
        
        if self.model != nil {
            if let components = GLLModelParams.meshNameRegexp.firstMatch(in: meshName, options: .anchored, range: NSRange(meshName.startIndex ..< meshName.endIndex, in: description)) {
                
                // 1st match: mesh group
                // Need this later for render parameters, so this part is always extracted.
                let meshGroupNumber = meshName[Range(components.range(at: 1), in: meshName)!]
                let meshGroup = "MeshGroup\(meshGroupNumber)"
                params.meshGroups = [ meshGroup ]
                
                // 2nd match: mesh name
                let namePart = meshName[Range(components.range(at: 2), in: meshName)!]
                // Parse parts of that for optional item
                if namePart.hasPrefix("+") || namePart.hasPrefix("-") {
                    params.visible = namePart.hasPrefix("+")
                    var remainder = namePart[namePart.index(after: namePart.startIndex) ..< namePart.endIndex]
                    
                    if let firstDot = remainder.firstIndex(of: ".") {
                        // Display name is everything after the dot. This can be an empty
                        // string. It can also be a useless string.
                        params.displayName = String(remainder.suffix(from: remainder.index(after: firstDot)))
                        remainder = remainder.prefix(upTo: firstDot)
                    }
                    
                    let optionalPartNames = remainder.components(separatedBy: "|")
                    params.optionalPartNames = optionalPartNames
                    if params.displayName == "" {
                        params.displayName = optionalPartNames.last ?? ""
                    }
                } else {
                    params.visible = true
                    params.optionalPartNames = []
                    params.displayName = String(namePart)
                }
                
                // 3rd, 4th, 5th match: render parameters
                let (shader, alpha) = getShaderAndAlpha(forMeshGroup: meshGroup) ?? (nil, true)
                params.shader = shader
                params.transparent = alpha
                
                // - Render parameters
                // The parameters follow a hierarchy:
                // 1. anything from parent
                // 2. own default values
                // 3. own specific values
                // If the same parameter is set twice, then the one the highest in the hierarchy wins. E.g. if a value is set by the parent, then here in a default value and finally here specifically, then the specific value here is the one used.
                var renderParameters: [String: Double] = [:]
                if let baseParams = base?.params(forMesh: meshName) {
                    renderParameters.merge(baseParams.renderParameters, uniquingKeysWith: { (_, new) in new })
                }
                if let defaultParams = plistData?.defaultRenderParameters {
                    renderParameters.merge(defaultParams, uniquingKeysWith: { (_, new) in new })
                }
                if let shader = shader {
                    if components.numberOfRanges < shader.parameterUniformNames.count + 3 {
                        print("Weird")
                    }
                    
                    for i in 0 ..< shader.parameterUniformNames.count {
                        var value = 0.0
                        if components.numberOfRanges >= i + 3 && components.range(at: i+3).location != NSNotFound {
                            let stringValue = meshName[Range(components.range(at: i+3), in: meshName)!]
                            value = Double(stringValue) ?? 0.0
                        }
                        
                        for parameterName in shader.genericMeshUniformMappings[i] {
                            renderParameters[parameterName] = value
                        }
                    }
                }
                params.renderParameters = renderParameters
                
                // 6th match: Camera name
                if components.numberOfRanges <= 6 || components.range(at: 6).location == NSNotFound {
                    params.cameraTargetName = nil;
                } else {
                    params.cameraTargetName = String(meshName[Range(components.range(at: 6), in: meshName)!]);
                }
                
                // Final matches: Camera bones
                if components.numberOfRanges <= 7 || components.range(at: 7).location == NSNotFound {
                    params.cameraTargetBones = [];
                } else {
                    var bones: [String] = []
                    for i in 7 ..< components.numberOfRanges {
                        bones.append(String(meshName[Range(components.range(at: i), in: meshName)!]))
                    }
                    params.cameraTargetBones = bones
                }
            } else {
                // Didn't match, so try and find anything from the default things
                if let baseParams = base?.params(forMesh: meshName) {
                    params.meshGroups = baseParams.meshGroups
                    
                    for meshGroup in params.meshGroups {
                        if let (shader, alpha) = getShaderAndAlpha(forMeshGroup: meshGroup) {
                            params.shader = shader
                            params.transparent = alpha
                            break
                        }
                    }

                    params.renderParameters = baseParams.renderParameters
                }
            }
        } else {
            let baseParams = base?.params(forMesh: meshName)
            
            var meshGroups: [String] = []
            if let ownGroups = plistData?.meshGroupNames {
                for (group, meshes) in ownGroups {
                    if meshes.contains(meshName) {
                        meshGroups.append(group)
                    }
                }
            }
            if let baseParams = baseParams {
                meshGroups.append(contentsOf: baseParams.meshGroups)
            }
            if meshGroups.count == 0, let defaultGroup = plistData?.defaultMeshGroup {
                meshGroups.append(defaultGroup)
            }
            params.meshGroups = meshGroups;
            
            // - Render parameters
            // The parameters follow a hierarchy:
            // 1. anything from parent
            // 2. own default values
            // 3. own specific values
            // If the same parameter is set twice, then the one the highest in the hierarchy wins. E.g. if a value is set by the parent, then here in a default value and finally here specifically, then the specific value here is the one used.
            var renderParameters: [String: Double] = [:]
            if let baseParams = baseParams {
                renderParameters.merge(baseParams.renderParameters, uniquingKeysWith: { (_, new) in new })
            }
            if let defaultParams = plistData?.defaultRenderParameters {
                renderParameters.merge(defaultParams, uniquingKeysWith: { (_, new) in new })
            }
            if let specificParams = plistData?.renderParameters?[meshName] {
                renderParameters.merge(specificParams, uniquingKeysWith: { (_, new) in new })
            }
            params.renderParameters = renderParameters
            
            // - Mesh splitters
            var splitters: [GLLMeshSplitter] = []
            if let ownSplitters = plistData?.meshSplitters?[meshName] {
                splitters.append(contentsOf: ownSplitters)
            }
            if let baseParams = baseParams {
                splitters.append(contentsOf: baseParams.splitters)
            }
            params.splitters = splitters
            
            // - Shader
            for meshGroup in params.meshGroups {
                if let (shader, alpha) = getShaderAndAlpha(forMeshGroup: meshGroup) {
                    params.shader = shader
                    params.transparent = alpha
                    break
                }
            }
        }
        
        return params
    }
    
    private func getShaderAndAlpha(forMeshGroup meshGroup: String) -> (GLLShaderDescription, Bool)? {
        // Try to find shader in own ones.
        if let shaders = plistData?.shaders {
            for (_, descriptor) in shaders {
                if descriptor.solidMeshGroups.contains(meshGroup) {
                    return (descriptor, false)
                }
                if descriptor.alphaMeshGroups.contains(meshGroup) {
                    return (descriptor, true)
                }
            }
        }
        
        // No luck. Get those from the base.
        return self.base?.getShaderAndAlpha(forMeshGroup: meshGroup)
    }
    
    /*
     * Camera targets
     */
    @objc var cameraTargets: [String] {
        if let model = self.model {
            
            var allTargets = Set<String>()
            for mesh in model.meshes {
                if let name = params(forMesh: mesh.name).cameraTargetName {
                    allTargets.insert(name)
                }
            }
            return Array<String>(allTargets)
        } else {
            var cameraTargets: [String] = []
            if let plistTargets = plistData?.cameraTargets {
                cameraTargets.append(contentsOf: plistTargets.keys)
            }
            if let base = self.base {
                cameraTargets.append(contentsOf: base.cameraTargets)
            }
            return cameraTargets
        }
    }
    @objc func boneNames(forCameraTarget target: String) -> [String] {
        if let model = model {
            var boneNames: [String] = []
            for mesh in model.meshes {
                let meshParams = params(forMesh: mesh.name)
                if let targetName = meshParams.cameraTargetName, targetName == target {
                    boneNames.append(contentsOf: meshParams.cameraTargetBones)
                }
            }
            return boneNames
        }
        if let boneNames = plistData?.cameraTargets?[target] {
            return boneNames
        }
        if let base = self.base {
            return base.boneNames(forCameraTarget: target)
        }
        
        return []
    }
    
    /*
     * Rendering
     */
    @objc func defaultValue(forRenderParameter name: String) -> Double {
        if let value = plistData?.defaultRenderParameters?[name] {
            return value
        }
        return self.base!.defaultValue(forRenderParameter: name)
    }
    @objc func defaultValue(forTexture name: String) -> URL {
        if let textureName = plistData?.defaultTextures?[name] {
            return Bundle.main.url(forResource: textureName, withExtension: nil)!
        }
        return self.base!.defaultValue(forTexture: name)
    }
    @objc func shader(name: String?) -> GLLShaderDescription? {
        guard let name = name else {
            return nil
        }
        
        if let description = plistData?.shaders?[name] {
            return description
        }
        if let base = self.base {
            return base.shader(name: name)
        }
        return nil
    }
    
    @objc lazy var allShaders: [GLLShaderDescription] = {
        var shaders: [GLLShaderDescription] = []
        if let ownShaders = plistData?.shaders {
            shaders.append(contentsOf: ownShaders.values)
        }
        if let base = base {
            shaders.append(contentsOf: base.allShaders)
        }
        return shaders
    }()
    
    @objc func description(forParameter name: String) -> GLLRenderParameterDescription {
        if let description = plistData?.renderParameterDescriptions?[name] {
            return description
        }
        return self.base!.description(forParameter: name)
    }
    @objc func description(forTexture name: String) -> GLLTextureDescription {
        if let description = plistData?.textureDescriptions?[name] {
            return description
        }
        return self.base!.description(forTexture: name)
    }
}
