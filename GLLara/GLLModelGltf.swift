//
//  GLLModelGltf.swift
//  GLLara
//
//  Created by Torsten Kammer on 07.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Cocoa

struct Accessor: Codable {
    var bufferView: String
    var byteOffset: Int
    var byteStride: Int
    var componentType: Int
    var count: Int
    var type: String
    var min: [Double]?
    var max: [Double]?
}

struct Asset: Codable {
    var version: String
}

struct BufferView: Codable {
    
}

struct Buffer: Codable {
    
}

struct Material: Codable {
    
}

struct Mesh: Codable {
    var primitives: [Primitive]
}

struct Primitive: Codable {
    var attributes: [String: String]
    var indices: String
    var material: String?
}

struct Node: Codable {
    var children: [String]
    var matrix: [Double]
    var name: String
}

struct Scene: Codable {
    
}

struct Skin: Codable {
    
}

struct GltfDocument: Codable {
    var accessors: [String: Accessor]?
    var asset: Asset?
    var bufferViews: [String: BufferView]?
    var buffers: [String: Buffer]?
    var extensionsUsed: [String]?
    var materials: [String: Material]?
    var meshes: [String: Mesh]?
    var scene: String?
    var scenes: [String: Scene]?
    var skins: [String: Skin]?
}

class GLLModelGltf: GLLModel {
    
    @objc convenience init(url: URL) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        try self.init(data: data, baseUrl: url)
    }
    
    @objc init(data: Data, baseUrl: URL) throws {
        let decoder = JSONDecoder()
        let document = try decoder.decode(GltfDocument.self, from: data)
        
        super.init()
        
        self.baseURL = baseUrl
        self.bones = []
        self.meshes = []
    }

}
