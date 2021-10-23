//
//  GLLModelParams.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLMeshParams: NSObject {
    @objc var meshGroups: [String] = []
    @objc var displayName: String = ""
    @objc var visible: Bool = true
    @objc var optionalPartNames: [String] = []
    @objc var xnaLaraShaderData: XnaLaraShaderDescription? = nil
    @objc var transparent: Bool = false
    @objc var renderParameters: [String: Double] = [:]
    @objc var splitters: [GLLMeshSplitter] = []
    
    var cameraTargetName: String? = nil
    var cameraTargetBones: [String] = []
}

@objc class GLLCameraTargetDescription: NSObject, Decodable {
    @objc let name: String
    @objc let boneNames: [String]
    
    init(name: String, boneNames: [String]) {
        self.name = name
        self.boneNames = boneNames
    }
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
        
        if let plistUrl = Bundle.main.url(forResource: name, withExtension: "modelparams.plist") {
            let data = try Data(contentsOf: plistUrl)
            let result = try GLLModelParams(data: data)
            parametersCache[name] = result
            return result
        } else if let jsonUrl = Bundle.main.url(forResource: name, withExtension: "modelparams.json") {
            let data = try Data(contentsOf: jsonUrl)
            let result = try GLLModelParams(data: data)
            parametersCache[name] = result
            return result
        } else {
            throw NSError(domain: "GLLModelParams", code: 1, userInfo: [
                NSLocalizedDescriptionKey : String(format:NSLocalizedString("Did not find model parameters for model type %@", comment: "Bundle didn't find Modelparams file."), name),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("GLLara stores special information for files not named generic_item. This information is not available", comment: "Bundle didn't find Modelparams file.")
                          ])
        }
    }
    
    struct PlistDataTransferObject: Decodable {
        /**
         * Name of a file that is essentially the superclass
         */
        var base: String?
        /**
         * Generic: The shaders that can be used, and the modules that can
         * apply. Presumably there will be only very few possible shaders, and
         * the variation is mainly in the modules.
         */
        var shaders: [GLLShaderBase]?
        /**
         * Generic: End user readable descriptions (or rather the localization
         * keys) for the various render parameters that shaders use. Render
         * parameters are identified internally by name; all parameters that
         * have the same name are assumed to do the same thing no matter who
         * uses them.
         */
        var renderParameterDescriptions: [String: GLLRenderParameterDescription]?
        /**
         * Default values to be used by the render parameters for the different
         * shaders. Default values can be set per model, or failing that,
         * in the base value.
         */
        var defaultRenderParameters: [String: Double]?
        /**
         * Generic: End user readable descriptions (or rather the localization
         * keys) for the various textures that shaders used. Same logic as for
         * render parameters
         */
        var textureDescriptions: [String: GLLTextureDescription]?
        /**
         * Generic: The default textures for the various texture types used.
         * In general these are designed to have no effect on rendering
         * whatsoever.
         */
        var defaultTextures: [String: String]?
        /**
         * For XNALara files: The mesh groups that apply to a mesh with the
         * given name for this model (may be more than one but only one of those
         * will actually render)
         */
        var meshGroupNames: [String: [String]]?
        /**
         * For XNALara files: Values for render parameters for meshes. Only
         * float render parameters get values in the plist because XNALara had
         * no color parameters
         */
        var renderParameters: [String: [String: Double]]?
        /**
         * For XNALara files: Pre-defined camera targets, and the bones that
         * belong to them.
         */
        var cameraTargets: [String: [String]]?
        /**
         * For XNALara files: The mesh group that all meshes belong to that
         * aren't menitoned in meshGroupNames
         */
        var defaultMeshGroup: String?
        /**
         * For XNALara files: Which meshes to split, and how. Very rare.
         */
        var meshSplitters: [String : [GLLMeshSplitter]]?
        /**
         * For XNALara files: Maps from an old shader name (which GLLara used
         * up to version 0.2.10) or from mesh group names to the base shader
         * and shader modules that are used now. Also provides some of the
         * hard-coded values to describe which texture gets used for what, and
         * which parameter value in a generic_mesh file gets used for what.
         *
         * This one doesn't need to be a map, it just makes it easier for me to
         * keep track
         */
        var xnaLaraShaderDescriptions: [String: XnaLaraShaderDescription]?
    }
    private let model: GLLModel?
    private let plistData: PlistDataTransferObject?
    
    private init(data: Data) throws {
        let plistDecoder = PropertyListDecoder()
        
        if let readData = try? plistDecoder.decode(PlistDataTransferObject.self, from: data) {
            plistData = readData
        } else {
            let jsonDecoder = JSONDecoder()
            plistData = try jsonDecoder.decode(PlistDataTransferObject.self, from: data)
        }
        
        model = nil
        
        if let baseName = plistData!.base {
            self.base = try GLLModelParams.parameters(forName: baseName)
        } else {
            self.base = nil
        }
        
        super.init()
    }
    
    // Generic item format
    init(model: GLLModel) throws {
        self.model = model
        self.base = try GLLModelParams.parameters(forName: "lara")
        self.plistData = nil
    }
    
    var base: GLLModelParams?
    
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
                params.xnaLaraShaderData = shader
                params.transparent = alpha
                
                // - Render parameters
                // The parameters follow a hierarchy:
                // 1. From render parameter descriptor
                // 2. Explicit defaults set in parent
                // 3. Explicit defaults set by this model
                // 4. Specific values set for this model
                // If the same parameter is set twice, then the one the highest in the hierarchy wins. E.g. if a value is set by the parent, then here in a default value and finally here specifically, then the specific value here is the one used.
                var renderParameters: [String: Double] = [:]
                if let baseParams = base?.params(forMesh: meshName) {
                    renderParameters.merge(baseParams.renderParameters, uniquingKeysWith: { (_, new) in new })
                }
                if let defaultParams = plistData?.defaultRenderParameters {
                    renderParameters.merge(defaultParams, uniquingKeysWith: { (_, new) in new })
                }
                if let shader = shader {
                    if components.numberOfRanges < shader.parameterUniformsInOrder.count + 3 {
                        print("Weird")
                    }
                    
                    for i in 0 ..< shader.parameterUniformsInOrder.count {
                        var value = 0.0
                        if components.numberOfRanges >= i + 3 && components.range(at: i+3).location != NSNotFound {
                            let stringValue = meshName[Range(components.range(at: i+3), in: meshName)!]
                            value = Double(stringValue) ?? 0.0
                        }
                        
                        for parameterName in shader.parameterUniformsInOrder[i] {
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
                            params.xnaLaraShaderData = shader
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
                    params.xnaLaraShaderData = shader
                    params.transparent = alpha
                    break
                }
            }
        }
        
        return params
    }
    
    private func getShaderAndAlpha(forMeshGroup meshGroup: String) -> (XnaLaraShaderDescription, Bool)? {
        // Try to find shader in own ones.
        if let shaders = plistData?.xnaLaraShaderDescriptions {
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
    @objc lazy var cameraTargets: [GLLCameraTargetDescription] = { () -> [GLLCameraTargetDescription] in
        var targets: [String: [String]] = [:]
        if let model = self.model {
            for mesh in model.meshes {
                let meshParams = params(forMesh: mesh.name)
                if let targetName = meshParams.cameraTargetName {
                    
                    let meshTarget = [targetName: meshParams.cameraTargetBones]
                    targets.merge(meshTarget, uniquingKeysWith: {(bonesA, bonesB) in bonesA + bonesB})
                }
            }
        }
        if let plistTargets = plistData?.cameraTargets {
            targets.merge(plistTargets, uniquingKeysWith: {(bonesA, bonesB) in bonesA + bonesB})
        }
        return targets.map { targetName, boneNames in GLLCameraTargetDescription(name: targetName, boneNames: boneNames) } + (base?.cameraTargets ?? [])
    }()
    
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
    @objc func defaultColor(forRenderParameter name: String) -> NSColor {
        return NSColor.black
    }
    
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
    
    /**
     Finds a shader for a model with the given base, modules, and present textures and vertex accessors and alpha blending value.
     The textures and vertex accessors are used to find additional modules that get automatically added - e.g. for normal mapping. The explicitly passed modules are used either way.
     */
    @objc func shader(base: String, modules: [String] = [], presentTextures: [String] = [], vertexAccessors: GLLVertexAttribAccessorSet, alphaBlending: Bool = false) -> GLLShaderData? {
        return shader(base: base, modules: modules, presentTextures: presentTextures, presentVertexAttributes: vertexAccessors.accessors.map { $0.attribute.semantic }, alphaBlending: alphaBlending)
    }
    
    /**
     Finds a shader for a model without using any implicit values: Only the modules that are there are actually used.
     */
    @objc func explicitShader(base: String, modules: [String] = [], texCoordAssignments: [String: Int], alphaBlending: Bool) -> GLLShaderData? {
        return shader(base: base, modules: modules, presentTextures: [], presentVertexAttributes: [], texCoordAssignments: texCoordAssignments, alphaBlending: alphaBlending)
    }
    
    func shader(base baseName: String, modules: [String] = [], presentTextures: [String] = [], presentVertexAttributes: [GLLVertexAttribSemantic] = [], texCoordAssignments: [String: Int] = [:], alphaBlending: Bool = false) -> GLLShaderData? {
        if let baseShader = plistData?.shaders?.first(where: { $0.name == baseName }) {
            let namedModules = baseShader.allModules(forNames: modules)
            let implicitModules = baseShader.descendantsMatching(textures: presentTextures, vertexAttributes: presentVertexAttributes)
            return GLLShaderData(base: baseShader, activeModules: namedModules + implicitModules, texCoordAssignments: texCoordAssignments, alphaBlending: alphaBlending, parameters: self)
        } else if let baseObject = base {
            return baseObject.shader(base: baseName, modules: modules, presentTextures: presentTextures, presentVertexAttributes: presentVertexAttributes, texCoordAssignments: texCoordAssignments, alphaBlending: alphaBlending)
        }
        return nil
    }
    
    @objc func shader(xnaData: XnaLaraShaderDescription, vertexAccessors: GLLVertexAttribAccessorSet, alphaBlending: Bool) -> GLLShaderData? {
        return shader(base: xnaData.baseName, modules: xnaData.moduleNames, presentTextures: xnaData.textureUniformsInOrder, presentVertexAttributes: vertexAccessors.accessors.map { $0.attribute.semantic }, texCoordAssignments: xnaData.texCoordSets, alphaBlending: alphaBlending)
    }
    
    @objc var xnaLaraShaderDescriptions: [XnaLaraShaderDescription] {
        if let ownDescriptions = plistData?.xnaLaraShaderDescriptions {
            return Array(ownDescriptions.values)
        }
        return base!.xnaLaraShaderDescriptions
    }
    
    @objc func xnaLaraShaderDescription(name: String) -> XnaLaraShaderDescription? {
        if let ownDescriptions = plistData?.xnaLaraShaderDescriptions, let description = ownDescriptions[name] {
            return description
        } else if let base = base {
            return base.xnaLaraShaderDescription(name: name)
        } else {
            return nil
        }
    }
}
