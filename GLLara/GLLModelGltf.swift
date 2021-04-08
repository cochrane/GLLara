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
    var buffer: String
    var byteOffset: Int
    var byteLength: Int?
}

struct Buffer: Codable {
    var uri: String
}

struct Material: Codable {
    var name: String?
}

struct Mesh: Codable {
    var primitives: [Primitive]
}

struct Primitive: Codable {
    var attributes: [String: String]
    var indices: String?
    var material: String
    var mode: Int?
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

class LoadedBuffer {
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
}

class LoadedBufferView {
    let buffer: LoadedBuffer
    let range: Range<Int>
    
    init(buffer: LoadedBuffer, range: Range<Int>) {
        self.buffer = buffer
        self.range = range
    }
}

class LoadedUnboundAccessor {
    let view: LoadedBufferView
    let accessor: Accessor
    
    init(view: LoadedBufferView, accessor: Accessor) {
        self.view = view
        self.accessor = accessor
    }
}

struct LoadData {
    let file: GltfDocument
    let baseUrl: URL
    
    var buffers: [String: LoadedBuffer] = [:]
    var bufferViews: [String: LoadedBufferView] = [:]
    var unboundAccessors: [String: LoadedUnboundAccessor] = [:]
    
    func loadData(uriString: String) throws -> Data {
        guard let uri = URL(string: uriString, relativeTo: baseUrl) else {
            throw NSError()
        }
        
        if uri.scheme == "data" && uri.absoluteString.contains(";base64,") {
            let components = uri.absoluteString.components(separatedBy: ";base64,")
            if components.count == 0 {
                throw NSError()
            }
            guard let encodedString = components.last, let data = Data(base64Encoded: encodedString, options: .ignoreUnknownCharacters) else {
                throw NSError()
            }
            return data
        }
        guard uri.isFileURL else {
            throw NSError()
        }
        
        return try Data(contentsOf: uri, options: .mappedIfSafe)
    }
    
    mutating func getBuffer(for key: String) throws -> LoadedBuffer {
        guard let fileBuffers = file.buffers else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffers"])
        }
        if let loadedBuffer = buffers[key] {
            return loadedBuffer;
        }
        
        guard let buffer = fileBuffers[key] else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed buffer"])
        }
        
        let data = try loadData(uriString: buffer.uri)
        let loadedBuffer = LoadedBuffer(data: data)
        buffers[key] = loadedBuffer
        return loadedBuffer
    }
    
    mutating func getBufferView(for key: String) throws -> LoadedBufferView {
        guard let fileViews = file.bufferViews else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffer views"])
        }
        if let loadedView = bufferViews[key] {
            return loadedView
        }
        
        guard let view = fileViews[key] else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed buffer view"])
        }
        
        let buffer = try getBuffer(for: view.buffer)
        let endIndex: Int
        if let byteLength = view.byteLength {
            endIndex = view.byteOffset + byteLength
        } else {
            endIndex = buffer.data.count
        }
        let loadedView = LoadedBufferView(buffer: buffer, range: view.byteOffset ..< endIndex)
        bufferViews[key] = loadedView
        return loadedView
    }
    
    mutating func getUnboundAccessor(for key: String) throws -> LoadedUnboundAccessor {
        guard let fileAccessors = file.accessors else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any accessors"])
        }
        if let loadedAccessor = unboundAccessors[key] {
            return loadedAccessor
        }
        
        guard let accessor = fileAccessors[key] else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed accessor"])
        }
        
        let view = try getBufferView(for: accessor.bufferView)
        let loadedAccessor = LoadedUnboundAccessor(view: view, accessor: accessor)
        unboundAccessors[key] = loadedAccessor
        return loadedAccessor
    }
}

class GLLModelGltf: GLLModel {
    
    @objc convenience init(url: URL) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        try self.init(data: data, baseUrl: url)
    }
    
    @objc init(data: Data, baseUrl: URL) throws {
        let decoder = JSONDecoder()
        let document = try decoder.decode(GltfDocument.self, from: data)
        
        var loadData = LoadData(file: document, baseUrl: baseUrl)
        
        super.init()
        
        self.parameters = try GLLModelParams.parameters(forName: "gltfFile")
        
        self.baseURL = baseUrl
        self.bones = []
        self.meshes = []
        
        // Load meshes
        if let meshes = document.meshes {
            var countOfVertices: Int? = nil
            var uvLayers = IndexSet()
            for keyAndMesh in meshes {
                for primitive in keyAndMesh.value.primitives {
                    
                    var accessors: [GLLVertexAttribAccessor] = []
                    for nameAndValue in primitive.attributes {
                        let fileAccessor = try loadData.getUnboundAccessor(for: nameAndValue.value)
                        
                        let nameComponents = nameAndValue.key.split(separator: "_")
                        let layer: Int
                        let name: String
                        if nameComponents.count == 2, let suffix = Int(nameComponents[1]) {
                            layer = suffix
                            name = String(nameComponents[0])
                        } else {
                            name = nameAndValue.key
                            layer = 0
                        }
                        
                        let semantic: GLLVertexAttribSemantic
                        switch name {
                        case "POSITION":
                            semantic = .position
                        case "NORMAL":
                            semantic = .normal
                        case "TEXCOORD":
                            semantic = .texCoord0
                        case "COLOR":
                            semantic = .color
                        case "JOINT":
                            semantic = .boneIndices
                        case "WEIGHT":
                            semantic = .boneWeights
                        default:
                            throw NSError()
                        }
                        
                        if semantic == .texCoord0 {
                            uvLayers.insert(layer)
                        }
                        
                        let size: GLLVertexAttribSize
                        switch fileAccessor.accessor.type {
                        case "SCALAR":
                            size = .scalar
                        case "VEC2":
                            size = .vec2
                        case "VEC3":
                            size = .vec3
                        case "VEC4":
                            size = .vec4
                        case "MAT2":
                            size = .mat2
                        case "MAT3":
                            size = .mat3
                        case "MAT4":
                            size = .mat4
                        default:
                            throw NSError()
                        }
                        
                        if ![5120, 5121, 5122, 5123, 5126].contains(fileAccessor.accessor.componentType) {
                            throw NSError()
                        }
                        let componentType = GLLVertexAttribComponentType(rawValue:  fileAccessor.accessor.componentType)!
                        
                        if let existingCount = countOfVertices {
                            if existingCount != fileAccessor.accessor.count {
                                throw NSError()
                            }
                        } else {
                            countOfVertices = fileAccessor.accessor.count
                        }
                        
                        let vertexAttrib = GLLVertexAttrib(semantic: semantic, layer: UInt(layer), size: size, componentType: componentType)
                        let vertexAccessor = GLLVertexAttribAccessor(attribute: vertexAttrib, dataBuffer: fileAccessor.view.buffer.data, offset: UInt(fileAccessor.accessor.byteOffset + fileAccessor.view.range.first!), stride: UInt(fileAccessor.accessor.byteStride))
                        accessors.append(vertexAccessor)
                    }
                    guard let countOfVertices = countOfVertices else {
                        throw NSError()
                    }
                    guard primitive.mode == 4 else {
                        throw NSError()
                    }
                    
                    let mesh = GLLModelMesh(asPartOf: self)!
                    mesh.name = keyAndMesh.key
                    mesh.displayName = mesh.name
                    mesh.textures = []
                    mesh.shader = self.parameters.shaderNamed("DefaultMaterial")
                    mesh.countOfVertices = UInt(countOfVertices)
                    mesh.countOfUVLayers = UInt(uvLayers.count)
                    mesh.vertexDataAccessors = GLLVertexAttribAccessorSet(accessors: accessors)
                    
                    if let indicesKey = primitive.indices {
                        let elements = try loadData.getUnboundAccessor(for: indicesKey)
                        mesh.elementData = elements.view.buffer.data.subdata(in: elements.view.range)
                        if ![5120, 5121, 5122, 5123, 5124, 5125, 5126].contains(elements.accessor.componentType) {
                            throw NSError()
                        }
                        mesh.elementComponentType = GLLVertexAttribComponentType(rawValue:  elements.accessor.componentType)!
                        mesh.countOfElements = UInt(elements.accessor.count)
                    } else {
                        mesh.elementData = nil
                        mesh.elementComponentType = .GllVertexAttribComponentTypeUnsignedByte
                        mesh.countOfElements = 0
                    }
                    
                    mesh.vertexFormat = mesh.vertexDataAccessors.vertexFormat(withVertexCount: UInt(mesh.countOfVertices), hasIndices: mesh.elementData != nil)
                                        
                    self.meshes.append(mesh)
                }
            }
        }
        
        // Set up the one and only bone we have for now
        self.bones = [GLLModelBone(model: self)]
    }

}
