//
//  GLLModel.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

let GLLModelLoadingErrorDomain = "GLL Model loading error domain";

enum GLLModelLoadingErrorCode: Int {
    case prematureEndOfFile
    case indexOutOfRange
    case circularReference
    case fileTypeNotSupported
    case parametersNotFound
}

/**
 * # A renderable object.
 *
 * A GLLModel corresponds to one mesh file (which actually contains many meshes; this is a bit confusing) and describes its graphics contexts. It contains some default transformations, but does not store poses and the like.
 */
@objc class GLLModel: NSObject {
    @objc var bones: [GLLModelBone] = []
    @objc var meshes: [GLLModelMesh] = []
    
    static let cachedModels = NSCache<NSString, GLLModel>()
    
    /**
     * # Returns a model with a given URL, returning a cached instance if one exists.
     *
     * Since a model is immutable here, it can be shared as much as necessary. This method uses an internal cache to share objects. Note that a model can be evicted from this cache again, if nobody is using it.
     */
    @objc static func cachedModel(from file: URL, parent: GLLModel? = nil) throws -> GLLModel {
        var key = file.absoluteString
        if let parent {
            key += "\n\(parent.baseURL.absoluteString)"
        }
        if let result = cachedModels.object(forKey: key as NSString) {
            return result
        }
        
        if file.pathExtension == "mesh" || file.pathExtension == "xps" {
            let model = try GLLModelXNALara(binaryFromFile: file, parent: parent)
            cachedModels.setObject(model, forKey: key as NSString)
            return model
        } else if file.lastPathComponent.hasSuffix(".mesh.ascii") {
            let model = try GLLModelXNALara(ASCIIFromFile: file, parent: parent)
            cachedModels.setObject(model, forKey: key as NSString)
            return model
        } else if file.pathExtension == "obj" {
            let model = try GLLModelObj(contentsOf: file)
            cachedModels.setObject(model, forKey: key as NSString)
            return model
        } else if file.pathExtension == ".gltf" {
            let model = try GLLModelGltf(url: file, isBinary: false)
            cachedModels.setObject(model, forKey: key as NSString)
            return model
        } else if file.pathExtension == ".glb" {
            let model = try GLLModelGltf(url: file, isBinary: true)
            cachedModels.setObject(model, forKey: key as NSString)
            return model
        } else {
            // Find display name for this extension
            let contentType = try file.resourceValues(forKeys: [.contentTypeKey]).contentType
            let fileTypeDescription = contentType?.localizedDescription ?? file.pathExtension
            
            throw NSError(domain: GLLModelLoadingErrorDomain, code: GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue, userInfo: [
                NSLocalizedDescriptionKey : String(format:NSLocalizedString("Files of type %@ are not supported.", comment: "Tried to load unsupported format"), fileTypeDescription),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Only .mesh, .mesh.ascii and .obj files can be loaded.", comment: "Tried to load unsupported format")
            ])

        }
    }

    @objc var baseURL: URL! = nil
    @objc var parameters: GLLModelParams! = nil
    
    @objc var hasBones: Bool {
        return bones.count > 0
    }
    
    @objc var rootBones: [GLLModelBone] {
        return bones.filter({ bone in bone.parent == nil } as (GLLModelBone)->Bool)
    }
    
    @objc var cameraTargetNames: [GLLCameraTargetDescription] {
        return parameters.cameraTargets
    }
    
    @objc func bone(name: String) -> GLLModelBone? {
        return bones.first { $0.name == name }
    }
}
