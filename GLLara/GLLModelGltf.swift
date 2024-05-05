//
//  GLLModelGltf.swift
//  GLLara
//
//  Created by Torsten Kammer on 07.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Cocoa

struct ColorRGBA {
    var red: Double = 0.0
    var green: Double = 0.0
    var blue: Double = 0.0
    var alpha: Double = 1.0
    
    static let white = ColorRGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let black = ColorRGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    var toNSColor: NSColor {
        return NSColor(calibratedRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}

extension ColorRGBA: Codable {
    init(from decoder: Decoder) throws {
        var array = try decoder.unkeyedContainer()
        red = try array.decode(Double.self)
        green = try array.decode(Double.self)
        blue = try array.decode(Double.self)
        alpha = try array.decode(Double.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var array = encoder.unkeyedContainer()
        try array.encode(red)
        try array.encode(green)
        try array.encode(blue)
        try array.encode(alpha)
    }
}

struct ColorRGB {
    var red: Double = 0.0
    var green: Double = 0.0
    var blue: Double = 0.0
    
    static let white = ColorRGB(red: 1.0, green: 1.0, blue: 1.0)
    static let black = ColorRGB(red: 1.0, green: 1.0, blue: 1.0)
    
    var toNSColor: NSColor {
        return NSColor(calibratedRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
}

extension ColorRGB: Codable {
    init(from decoder: Decoder) throws {
        var array = try decoder.unkeyedContainer()
        red = try array.decode(Double.self)
        green = try array.decode(Double.self)
        blue = try array.decode(Double.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var array = encoder.unkeyedContainer()
        try array.encode(red)
        try array.encode(green)
        try array.encode(blue)
    }
}

struct Accessor: Codable {
    var bufferView: Int
    var byteOffset: Int?
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

struct Image: Codable {
    var uri: String?
    var mimeType: String?
    var bufferView: Int?
    var name: String?
}

struct Material: Codable {
    var name: String?
    var pbrMetallicRoughness: PbrMetallicRoughness?
    var normalTexture: TextureInfo?
    var occlusionTexture: OcclusionTextureInfo?
    var emissiveTexture: TextureInfo?
    var emissiveFactor: ColorRGB?
    var alphaMode: String?
    var alphaCutoff: Double?
    var doubleSided: Bool?
    
    var extensions: MaterialExtensions?
}

struct MaterialExtensions {
    var isUnlit: Bool
    
    // KHR_materials_clearcoat - we don't support this yet, just parsing it in case we want to in the future
    struct Clearcoat: Codable {
        var factor: Double?
        var texture: TextureInfo?
        var roughnessFactor: Double?
        var roughnessTexture: TextureInfo?
        var normalTexture: NormalTextureInfo?
        
        enum CodingKeys: String, CodingKey {
            case factor = "clearcoatFactor"
            case texture = "clearcoatTexture"
            case roughnessFactor = "clearcoatRoughnessFactor"
            case roughnessTexture = "clearcoatRoughnessTexture"
            case normalTexture = "clearcoatNormalTexture"
        }
    }
    
    struct PBRSpecularGlossiness: Codable {
        var diffuseFactor: ColorRGBA?
        var diffuseTexture: TextureInfo?
        var specularFactor: ColorRGB?
        var glossinessFactor: Double?
        var specularGlossinessTexture: TextureInfo?
    }
    
    struct Sheen: Codable {
        var colorFactor: ColorRGB?
        var colorTexture: TextureInfo?
        var roughnessFactor: [Double]?
        var roughnessTexture: TextureInfo?
        
        enum CodingKeys: String, CodingKey {
            case colorFactor = "sheenColorFactor"
            case colorTexture = "sheenColorTexture"
            case roughnessFactor = "sheenRoughnessFactor"
            case roughnessTexture = "sheenRoughnessTexture"
        }
    }
    
    struct Transmission: Codable {
        var factor: Double?
        var texture: TextureInfo?
        
        enum CodingKeys: String, CodingKey {
            case factor = "transmissionFactor"
            case texture = "transmissionTexture"
        }
    }
    
    var clearcoat: Clearcoat?
    var pbrSpecularGlossiness: PBRSpecularGlossiness?
    var sheen: Sheen?
    var transmission: Transmission?
}

extension MaterialExtensions: Codable {
    enum ExtensionKey: String, CodingKey {
        case KHR_materials_unlit
        case KHR_materials_clearcoat
        case KHR_materials_pbrSpecularGlossiness
        case KHR_materials_sheen
        case KHR_materials_transmission
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ExtensionKey.self)
        
        // Unlit is just a flag, contains no other information
        isUnlit = container.contains(.KHR_materials_unlit)
        
        clearcoat = try container.decodeIfPresent(Clearcoat.self, forKey: .KHR_materials_clearcoat)
        pbrSpecularGlossiness = try container.decodeIfPresent(PBRSpecularGlossiness.self, forKey: .KHR_materials_pbrSpecularGlossiness)
        sheen = try container.decodeIfPresent(Sheen.self, forKey: .KHR_materials_sheen)
        transmission = try container.decodeIfPresent(Transmission.self, forKey: .KHR_materials_transmission)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ExtensionKey.self)
        
        if isUnlit {
            // Per specification, isUnlit provides an empty object
            // Keying by ExtensionKey because it's free and lying around
            _ = container.nestedContainer(keyedBy: ExtensionKey.self, forKey: .KHR_materials_unlit)
        }
        
        try container.encodeIfPresent(clearcoat, forKey: .KHR_materials_clearcoat)
        try container.encodeIfPresent(pbrSpecularGlossiness, forKey: .KHR_materials_pbrSpecularGlossiness)
        try container.encodeIfPresent(sheen, forKey: .KHR_materials_sheen)
        try container.encodeIfPresent(transmission, forKey: .KHR_materials_transmission)
    }
}

struct Mesh: Codable {
    var name: String?
    var primitives: [Primitive]
}

struct PbrMetallicRoughness: Codable {
    var baseColorFactor: ColorRGBA?
    var baseColorTexture: TextureInfo?
    var metallicFactor: Double?
    var roughnessFactor: Double?
    var metallicRoughnessTexture: TextureInfo?
}

struct Primitive: Codable, Equatable {
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

struct Sampler: Codable {
    var magFilter: Int?
    var minFilter: Int?
    var wrapS: Int?
    var wrapT: Int?
    var name: String?
}

struct Scene: Codable {
    
}

struct Skin: Codable {
    
}

struct Texture: Codable {
    var sampler: Int?
    var source: Int?
    var name: String?
}

struct TextureInfo: Codable {
    var index: Int
    var texCoord: Int?
}

struct OcclusionTextureInfo: Codable {
    var index: Int
    var texCoord: Int?
    var strength: Double?
}

struct NormalTextureInfo: Codable {
    var index: Int
    var texCoord: Int?
    var scale: Double?
}

struct GltfDocument: Codable {
    var accessors: [Accessor]?
    var asset: Asset
    var bufferViews: [BufferView]?
    var buffers: [Buffer]?
    var extensionsUsed: [String]?
    var extensionsRequired: [String]?
    var images: [Image]?
    var materials: [Material]?
    var meshes: [Mesh]?
    var nodes: [Node]?
    var samplers: [Sampler]?
    var scene: Int?
    var scenes: [Scene]?
    var skins: [Skin]?
    var textures: [Texture]?
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
    
    func makeURI(from uriString: String) -> URL {
        // Try normal path, for data: URLs
        if let uri = URL(string: uriString, relativeTo: baseUrl) {
            return uri;
        }
        // If that's invalid, that might be because of spaces in the filename, which is illegal for general URLs but obviously legal in paths
        return URL(fileURLWithPath: uriString, relativeTo: baseUrl)
    }
    
    func loadData(uriString: String) throws -> Data {
        let uri = makeURI(from: uriString)
        
        if uri.scheme == "data" && uri.absoluteString.contains(";base64,") {
            let components = uri.absoluteString.components(separatedBy: ";base64,")
            if components.count == 0 {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The data URI is incomplete."])
            }
            guard let encodedString = components.last, let data = Data(base64Encoded: encodedString, options: .ignoreUnknownCharacters) else {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The data URI is invalid."])
            }
            return data
        }
        guard uri.isFileURL else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Loading data via the internet is disabled for security reasons."])

        }
        
        return try Data(contentsOf: uri, options: .mappedIfSafe)
    }
    
    mutating func getBuffer(for index: Int) throws -> LoadedBuffer {
        guard let fileBuffers = file.buffers else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffers"])
        }
        guard index < fileBuffers.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed buffer"])
        }
        if let loadedBuffer = buffers[index] {
            return loadedBuffer;
        }
        
        let buffer = fileBuffers[index]
        guard let uri = buffer.uri else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Buffer without URI where it shouldn't be"])
        }
        
        let data = try loadData(uriString: uri)
        let loadedBuffer = LoadedBuffer(data: data)
        buffers[index] = loadedBuffer
        return loadedBuffer
    }
    
    mutating func getBufferView(for index: Int) throws -> LoadedBufferView {
        guard let fileViews = file.bufferViews else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any buffer views"])
        }
        guard index < fileViews.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed buffer view"])
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
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain any accessors"])
        }
        guard index < fileAccessors.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file doesn't contain a needed accessor"])
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
    func readInt<T: BinaryInteger>(at: Data.Index, type: T.Type) throws -> T {
        guard at + MemoryLayout<T>.size <= self.count else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is missing some data."])
        }
        var result: T = 0
        _ = Swift.withUnsafeMutableBytes(of: &result) { bytes in
            copyBytes(to: bytes.bindMemory(to: UInt8.self), from: at ..< at + MemoryLayout<T>.size)
        }
        return result
    }
    
    func readUInt32(at index: Data.Index) throws -> UInt32 {
        return try readInt(at: index, type: UInt32.self)
    }
    func readInt32(at index: Data.Index) throws -> Int32 {
        return try readInt(at: index, type: Int32.self)
    }
    func readUInt16(at index: Data.Index) throws -> UInt16 {
        return try readInt(at: index, type: UInt16.self)
    }
    func readInt16(at index: Data.Index) throws -> Int16 {
        return try readInt(at: index, type: Int16.self)
    }
    func readUInt8(at index: Data.Index) throws -> UInt8 {
        return try readInt(at: index, type: UInt8.self)
    }
    func readInt8(at index: Data.Index) throws -> Int8 {
        return try readInt(at: index, type: Int8.self)
    }
    
    mutating public func append(_ newElement: Float32) {
        _ = Swift.withUnsafeBytes(of: newElement) {
            self.append(contentsOf: $0)
        }
    }
    
    mutating public func append(_ newElement: UInt16) {
        _ = Swift.withUnsafeBytes(of: newElement) {
            self.append(contentsOf: $0)
        }
    }
    
    func checkedSubdata(in range: Range<Data.Index>) throws -> Data {
        if range.max() ?? 0 > self.count {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is missing some data."])
        }
        return subdata(in: range)
    }
}

class GLLModelGltf: GLLModel {
    
    convenience init(url: URL, isBinary: Bool = false) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        
        if (isBinary) {
            if data.count < 12 {
                // No header
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is too short to contain a glTF binary header."])
            }
            let magic = try data.readUInt32(at: 0)
            if (magic != 0x46546C67) {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file is not a binary glTF file."])
            }
            let version = try data.readUInt32(at: 4)
            if version == 2 {
                let chunkLengthJson = try data.readUInt32(at: 12)
                let chunkTypeJson = try data.readUInt32(at: 16)
                if chunkTypeJson != 0x4E4F534A {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
                }
                if chunkLengthJson + 20 > data.count {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.indexOutOfRange.rawValue), userInfo: [NSLocalizedDescriptionKey: "The file cannot be loaded because the file size is incorrect."])
                }
                let jsonEnd = Int(20 + chunkLengthJson)
                let jsonData = try data.checkedSubdata(in: 20 ..< jsonEnd)
                
                let binaryData: Data?
                if jsonEnd < data.count {
                    let chunkLengthBinary = try data.readUInt32(at: jsonEnd)
                    let chunkTypeBinary = try data.readUInt32(at: jsonEnd + 4)
                    if chunkTypeBinary != 0x004E4942 {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
                    }
                    let binaryEnd = jsonEnd + 8 + Int(chunkLengthBinary)
                    binaryData = try data.checkedSubdata(in: jsonEnd + 8 ..< binaryEnd)
                } else {
                    binaryData = nil
                }
                
                try self.init(jsonData: jsonData, baseUrl: url, binaryData: binaryData)
            } else {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The binary glTF container format version is not supported."])
            }
        } else {
            try self.init(jsonData: data, baseUrl: url)
        }
    }
    
    private func semanticAndLayer(for attributeKey: String) -> (GLLVertexAttribSemantic, Int)? {
        let nameComponents = attributeKey.split(separator: "_")
        let layer: Int
        let name: String
        if nameComponents.count == 2, let suffix = Int(nameComponents[1]) {
            layer = suffix
            name = String(nameComponents[0])
        } else {
            name = attributeKey
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
            return nil
        }
        return (semantic, layer)
    }
    
    private func load(primitive: Primitive, fromMesh mesh: Mesh, loadData: inout LoadData, document: GltfDocument) throws {
        var countOfVertices: Int? = nil
        var uvLayers = IndexSet()
        
        var accessors: [GLLVertexAttribAccessor] = []
        for (attributeKey, attributeIndex) in primitive.attributes {
            let fileAccessor = try loadData.getUnboundAccessor(for: attributeIndex)
            
            guard let (semantic, layer) = semanticAndLayer(for: attributeKey) else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute semantic is not supported."])
            }
            
            if semantic == .texCoord0 {
                uvLayers.insert(layer)
            }
            
            let format: MTLVertexFormat
            switch fileAccessor.accessor.type {
            case "SCALAR":
                switch fileAccessor.accessor.componentType {
                case 0x1400: // Byte
                    format = .char
                case 0x1401:
                    format = .uchar
                case 0x1402:
                    format = .short
                case 0x1403:
                    format = .ushort
                case 0x1404:
                    format = .int
                case 0x1405:
                    format = .uint
                case 0x1406:
                    format = .float
                default:
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            case "VEC2":
                switch fileAccessor.accessor.componentType {
                case 0x1400: // Byte
                    format = .char2
                case 0x1401:
                    format = .uchar2
                case 0x1402:
                    format = .short2
                case 0x1403:
                    format = .ushort2
                case 0x1404:
                    format = .int2
                case 0x1405:
                    format = .uint2
                case 0x1406:
                    format = .float2
                default:
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            case "VEC3":
                switch fileAccessor.accessor.componentType {
                case 0x1400: // Byte
                    format = .char3
                case 0x1401:
                    format = .uchar3
                case 0x1402:
                    format = .short3
                case 0x1403:
                    format = .ushort3
                case 0x1404:
                    format = .int3
                case 0x1405:
                    format = .uint3
                case 0x1406:
                    format = .float3
                default:
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            case "VEC4":
                switch fileAccessor.accessor.componentType {
                case 0x1400: // Byte
                    format = .char4
                case 0x1401:
                    format = .uchar4
                case 0x1402:
                    format = .short4
                case 0x1403:
                    format = .ushort4
                case 0x1404:
                    format = .int4
                case 0x1405:
                    format = .uint4
                case 0x1406:
                    format = .float4
                default:
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            case "MAT2":
                switch fileAccessor.accessor.componentType {
                default:
                    // TODO Consider splitting into multiple attributes
                    // In general accessors with these types are not intended for vertices, but for bones and similar.
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            case "MAT3":
                switch fileAccessor.accessor.componentType {
                default:
                    // TODO Consider splitting into multiple attributes.
                    // In general accessors with these types are not intended for vertices, but for bones and similar.
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            case "MAT4":
                switch fileAccessor.accessor.componentType {
                default:
                    // TODO Consider splitting into multiple attributes
                    // In general accessors with these types are not intended for vertices, but for bones and similar.
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute type value is not supported."])
                }
            default:
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "A vertex attribute size value is not supported."])
            }
            
            if let existingCount = countOfVertices {
                if existingCount != fileAccessor.accessor.count {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The vertex size value is wonky."])
                }
            } else {
                countOfVertices = fileAccessor.accessor.count
            }
            
            let underlyingView = document.bufferViews![fileAccessor.accessor.bufferView]
            let vertexAttrib = GLLVertexAttrib(semantic: semantic, layer: layer, format: format)
            let vertexAccessor = GLLVertexAttribAccessor(attribute: vertexAttrib, dataBuffer: fileAccessor.view.buffer.data, offset: fileAccessor.accessor.byteOffset ?? 0 + fileAccessor.view.range.first!, stride: underlyingView.byteStride ?? 0)
            accessors.append(vertexAccessor)
        }
        guard let finalCountOfVertices = countOfVertices else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The vertex size value is wonky."])
        }
        guard primitive.mode ?? 4 == 4 else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "Only sets of triangles are supported."])
        }
        
        let modelMesh = GLLModelMesh(asPartOfModel: self)
        modelMesh.name = mesh.name ?? "mesh"
        if mesh.primitives.count > 1, let primitiveIndex = mesh.primitives.firstIndex(of: primitive) {
            modelMesh.name = modelMesh.name + " part \(primitiveIndex)"
        }
        modelMesh.displayName = modelMesh.name
        modelMesh.textures = [:]
        modelMesh.shader = self.parameters.shader(base: "glTFDefault")
        modelMesh.countOfVertices = finalCountOfVertices
        modelMesh.countOfUVLayers = uvLayers.count
        modelMesh.vertexDataAccessors = GLLVertexAttribAccessorSet(accessors: accessors)
        modelMesh.renderParameterValues = [:]
        
        if let materialIndex = primitive.material, let material = document.materials?[materialIndex] {
            var textures: [String] = []
            if material.pbrMetallicRoughness?.baseColorTexture != nil {
                textures.append("baseColorTexture")
                // Load the texture
                // TODO
            }
            
            let isUnlitInFile = material.extensions?.isUnlit ?? false
            let alwaysUseUnlit = true
            if isUnlitInFile || alwaysUseUnlit {
                let vertexAttributes = accessors.map {
                    $0.attribute.semantic
                }
                
                // Use unlit shader; let model system work out the rest
                modelMesh.shader = self.parameters.shader(base: "glTFUnlit", modules: [], presentTextures: textures, presentVertexAttributes: vertexAttributes )
            }
            
            let baseColor = material.pbrMetallicRoughness?.baseColorFactor ?? ColorRGBA.white
            modelMesh.renderParameterValues["baseColorFactor"] = baseColor.toNSColor;
        }
        
        if let indicesKey = primitive.indices {
            let elements = try loadData.getUnboundAccessor(for: indicesKey)
            modelMesh.elementData = elements.view.buffer.data.subdata(in: elements.view.range)
            switch elements.accessor.componentType {
            case 0x1400: // Byte (treating as if it was unsigned)
                modelMesh.elementSize = 1
            case 0x1401: // Unsigned byte
                modelMesh.elementSize = 1
            case 0x1402: // Short (treating it as unsigned)
                modelMesh.elementSize = 2
            case 0x1403: // Unsigned short
                modelMesh.elementSize = 2
            case 0x1404: // Int (treating it as unsigned
                modelMesh.elementSize = 4
            case 0x1405: // Unsigned int
                modelMesh.elementSize = 4
            default:
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.fileTypeNotSupported.rawValue), userInfo: [NSLocalizedDescriptionKey: "The element data type is not supported."])
            }
            modelMesh.countOfElements = elements.accessor.count
        } else {
            modelMesh.elementData = nil
            modelMesh.elementSize = 0
            modelMesh.countOfElements = 0
        }
        
        modelMesh.vertexFormat = modelMesh.vertexDataAccessors!.vertexFormat(vertexCount: modelMesh.countOfVertices, hasIndices: modelMesh.elementData != nil)
                            
        self.meshes.append(modelMesh)
    }
    
    init(jsonData: Data, baseUrl: URL, binaryData: Data? = nil) throws {
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
            for mesh in meshes {
                for primitive in mesh.primitives {
                    try load(primitive: primitive, fromMesh: mesh, loadData: &loadData, document: document)
                }
            }
        }
        
        // Set up the one and only bone we have for now
        self.bones = [GLLModelBone()]
    }

}
