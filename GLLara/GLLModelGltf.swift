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
    
    init(file: GltfDocument, baseUrl: URL, binaryData: Data?) {
        self.file = file
        self.baseUrl = baseUrl
        
        if let binary = binaryData {
            buffers["binary_glTF"] = LoadedBuffer(data: binary)
        }
    }
    
    func loadData(uriString: String) throws -> Data {
        guard let uri = URL(string: uriString, relativeTo: baseUrl) else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The URI is invalid."])
        }
        
        if uri.scheme == "data" && uri.absoluteString.contains(";base64,") {
            let components = uri.absoluteString.components(separatedBy: ";base64,")
            if components.count == 0 {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The data URI is incomplete."])
            }
            guard let encodedString = components.last, let data = Data(base64Encoded: encodedString, options: .ignoreUnknownCharacters) else {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The data URI is invalid."])
            }
            return data
        }
        guard uri.isFileURL else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Loading data via the internet is disabled for security reasons."])

        }
        
        return try Data(contentsOf: uri, options: .mappedIfSafe)
    }
    
    mutating func getBuffer(for key: String) throws -> LoadedBuffer {
        if let loadedBuffer = buffers[key] {
            return loadedBuffer;
        }
        guard let fileBuffers = file.buffers else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffers"])
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

extension Data {
    func readUInt32(at: Data.Index) throws -> UInt32 {
        guard at + 4 <= self.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is missing some data."])
        }
        var result: UInt32 = 0
        _ = Swift.withUnsafeMutableBytes(of: &result, { self.copyBytes(to: $0, from: at ..< at + 4) })
        return result
    }
    
    func checkedSubdata(in range: Range<Data.Index>) throws -> Data {
        if range.max() ?? 0 > self.count {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is missing some data."])
        }
        return subdata(in: range)
    }
}

class GLLModelGltf: GLLModel {
    
    @objc convenience init(url: URL, isBinary: Bool = false) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        
        if (isBinary) {
            if data.count < 12 {
                // No header
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is too short to contain a glTF binary header."])
            }
            let magic = try data.readUInt32(at: 0)
            if (magic != 0x46546C67) {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is not a binary glTF file."])
            }
            let version = try data.readUInt32(at: 4)
            if version == 1 {
                let contentLength = try data.readUInt32(at: 12)
                let contentFormat = try data.readUInt32(at: 16)
                if contentFormat != 0 {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
                }
                if contentLength + 20 > data.count {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_IndexOutOfRange.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file cannot be loaded because the file size is incorrect."])
                }
                
                let jsonEnd = Int(20 + contentLength)
                let jsonData = try data.checkedSubdata(in: 20 ..< jsonEnd)
                let binaryData = try data.checkedSubdata(in: jsonEnd ..< data.count)
                
                try self.init(jsonData: jsonData, baseUrl: url, binaryData: binaryData)
            } else if version == 2 {
                let chunkLengthJson = try data.readUInt32(at: 12)
                let chunkTypeJson = try data.readUInt32(at: 12)
                if chunkTypeJson != 0x4E4F534A {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
                }
                if chunkLengthJson + 20 > data.count {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_IndexOutOfRange.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file cannot be loaded because the file size is incorrect."])
                }
                let jsonEnd = Int(20 + chunkLengthJson)
                let jsonData = try data.checkedSubdata(in: 20 ..< jsonEnd)
                
                let binaryData: Data?
                if jsonEnd < data.count {
                    let chunkLengthBinary = try data.readUInt32(at: jsonEnd)
                    let chunkTypeBinary = try data.readUInt32(at: jsonEnd + 4)
                    if chunkTypeBinary != 0x004E4942 {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
                    }
                    let binaryEnd = jsonEnd + 8 + Int(chunkLengthBinary)
                    binaryData = try data.checkedSubdata(in: jsonEnd + 8 ..< binaryEnd)
                } else {
                    binaryData = nil
                }
                
                try self.init(jsonData: jsonData, baseUrl: url, binaryData: binaryData)
            } else {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
            }
        } else {
            try self.init(jsonData: data, baseUrl: url)
        }
    }
    
    @objc init(jsonData: Data, baseUrl: URL, binaryData: Data? = nil) throws {
        let decoder = JSONDecoder()
        let document = try decoder.decode(GltfDocument.self, from: jsonData)
        
        var loadData = LoadData(file: document, baseUrl: baseUrl, binaryData: binaryData)
        
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
                            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute semantic is not supported."])
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
                            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute size value is not supported."])
                        }
                        
                        if ![5120, 5121, 5122, 5123, 5126].contains(fileAccessor.accessor.componentType) {
                            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])

                        }
                        let componentType = GLLVertexAttribComponentType(rawValue:  fileAccessor.accessor.componentType)!
                        
                        if let existingCount = countOfVertices {
                            if existingCount != fileAccessor.accessor.count {
                                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The vertex size value is wonky."])
                            }
                        } else {
                            countOfVertices = fileAccessor.accessor.count
                        }
                        
                        let vertexAttrib = GLLVertexAttrib(semantic: semantic, layer: UInt(layer), size: size, componentType: componentType)
                        let vertexAccessor = GLLVertexAttribAccessor(attribute: vertexAttrib, dataBuffer: fileAccessor.view.buffer.data, offset: UInt(fileAccessor.accessor.byteOffset + fileAccessor.view.range.first!), stride: UInt(fileAccessor.accessor.byteStride))
                        accessors.append(vertexAccessor)
                    }
                    guard let countOfVertices = countOfVertices else {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The vertex size value is wonky."])
                    }
                    guard primitive.mode == 4 else {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Only sets of triangles are supported."])
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
                            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The element data type is not supported."])
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
