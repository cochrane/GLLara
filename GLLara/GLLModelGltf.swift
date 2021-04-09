//
//  GLLModelGltf.swift
//  GLLara
//
//  Created by Torsten Kammer on 07.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Cocoa

struct Accessor: Codable {
    var bufferView: Int
    var byteOffset: Int
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
    var buffer: Int
    var byteOffset: Int
    var byteLength: Int?
    var byteStride: Int?
}

struct Buffer: Codable {
    var uri: String?
}

struct Material: Codable {
    var name: String?
}

struct Mesh: Codable {
    var name: String?
    var primitives: [Primitive]
}

struct Primitive: Codable {
    var attributes: [String: Int]
    var indices: Int?
    var material: Int?
    var mode: Int?
}

struct Node: Codable {
    var children: [Int]?
    var matrix: [Double]?
    var name: String?
}

struct Scene: Codable {
    
}

struct Skin: Codable {
    
}

struct GltfDocument: Codable {
    var accessors: [Accessor]?
    var asset: Asset
    var bufferViews: [BufferView]?
    var buffers: [Buffer]?
    var materials: [Material]?
    var meshes: [Mesh]?
    var nodes: [Node]?
    var scene: Int?
    var scenes: [Scene]?
    var skins: [Skin]?
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
    
    var buffers: [LoadedBuffer?]
    var bufferViews: [LoadedBufferView?]
    var unboundAccessors: [LoadedUnboundAccessor?]
    
    init(file: GltfDocument, baseUrl: URL, binaryData: Data?) {
        self.file = file
        self.baseUrl = baseUrl
        
        self.buffers = Array<LoadedBuffer?>.init(repeating: nil, count: file.buffers?.count ?? 0)
        self.bufferViews = Array<LoadedBufferView?>.init(repeating: nil, count: file.bufferViews?.count ?? 0)
        self.unboundAccessors = Array<LoadedUnboundAccessor?>.init(repeating: nil, count: file.accessors?.count ?? 0)
        
        if let binary = binaryData, buffers.count > 0 {
            buffers[0] = LoadedBuffer(data: binary)
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
    
    mutating func getBuffer(for index: Int) throws -> LoadedBuffer {
        guard let fileBuffers = file.buffers else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffers"])
        }
        guard index < fileBuffers.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed buffer"])
        }
        if let loadedBuffer = buffers[index] {
            return loadedBuffer;
        }
        
        let buffer = fileBuffers[index]
        guard let uri = buffer.uri else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Buffer without URI where it shouldn't be"])
        }
        
        let data = try loadData(uriString: uri)
        let loadedBuffer = LoadedBuffer(data: data)
        buffers[index] = loadedBuffer
        return loadedBuffer
    }
    
    mutating func getBufferView(for index: Int) throws -> LoadedBufferView {
        guard let fileViews = file.bufferViews else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffer views"])
        }
        guard index < fileViews.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed buffer view"])
        }
        if let loadedView = bufferViews[index] {
            return loadedView
        }
        
        let view = fileViews[index]
        let buffer = try getBuffer(for: view.buffer)
        let endIndex: Int
        if let byteLength = view.byteLength {
            endIndex = view.byteOffset + byteLength
        } else {
            endIndex = buffer.data.count
        }
        let loadedView = LoadedBufferView(buffer: buffer, range: view.byteOffset ..< endIndex)
        bufferViews[index] = loadedView
        return loadedView
    }
    
    mutating func getUnboundAccessor(for index: Int) throws -> LoadedUnboundAccessor {
        guard let fileAccessors = file.accessors else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any accessors"])
        }
        guard index < fileAccessors.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed accessor"])
        }
        if let loadedAccessor = unboundAccessors[index] {
            return loadedAccessor
        }
        
        
        let accessor = fileAccessors[index]
        let view = try getBufferView(for: accessor.bufferView)
        let loadedAccessor = LoadedUnboundAccessor(view: view, accessor: accessor)
        unboundAccessors[index] = loadedAccessor
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
            if version == 2 {
                let chunkLengthJson = try data.readUInt32(at: 12)
                let chunkTypeJson = try data.readUInt32(at: 16)
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
            for mesh in meshes {
                for primitive in mesh.primitives {
                    
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
                        
                        let underlyingView = document.bufferViews![fileAccessor.accessor.bufferView]
                        let vertexAttrib = GLLVertexAttrib(semantic: semantic, layer: UInt(layer), size: size, componentType: componentType)
                        let vertexAccessor = GLLVertexAttribAccessor(attribute: vertexAttrib, dataBuffer: fileAccessor.view.buffer.data, offset: UInt(fileAccessor.accessor.byteOffset + fileAccessor.view.range.first!), stride: UInt(underlyingView.byteStride ?? 0))
                        accessors.append(vertexAccessor)
                    }
                    guard let countOfVertices = countOfVertices else {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The vertex size value is wonky."])
                    }
                    guard primitive.mode == 4 else {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Only sets of triangles are supported."])
                    }
                    
                    let modelMesh = GLLModelMesh(asPartOf: self)!
                    modelMesh.name = mesh.name ?? "mesh"
                    modelMesh.displayName = modelMesh.name
                    modelMesh.textures = []
                    modelMesh.shader = self.parameters.shaderNamed("DefaultMaterial")
                    modelMesh.countOfVertices = UInt(countOfVertices)
                    modelMesh.countOfUVLayers = UInt(uvLayers.count)
                    modelMesh.vertexDataAccessors = GLLVertexAttribAccessorSet(accessors: accessors)
                    
                    if let indicesKey = primitive.indices {
                        let elements = try loadData.getUnboundAccessor(for: indicesKey)
                        modelMesh.elementData = elements.view.buffer.data.subdata(in: elements.view.range)
                        if ![5120, 5121, 5122, 5123, 5124, 5125, 5126].contains(elements.accessor.componentType) {
                            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_FileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The element data type is not supported."])
                        }
                        modelMesh.elementComponentType = GLLVertexAttribComponentType(rawValue:  elements.accessor.componentType)!
                        modelMesh.countOfElements = UInt(elements.accessor.count)
                    } else {
                        modelMesh.elementData = nil
                        modelMesh.elementComponentType = .GllVertexAttribComponentTypeUnsignedByte
                        modelMesh.countOfElements = 0
                    }
                    
                    modelMesh.vertexFormat = modelMesh.vertexDataAccessors.vertexFormat(withVertexCount: UInt(modelMesh.countOfVertices), hasIndices: modelMesh.elementData != nil)
                                        
                    self.meshes.append(modelMesh)
                }
            }
        }
        
        // Set up the one and only bone we have for now
        self.bones = [GLLModelBone(model: self)]
    }

}
