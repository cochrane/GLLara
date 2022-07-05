//
//  GLLModelMesh.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

/*!
 * @abstract Vertex and element data.
 * @discussion A GLLMesh stores a set of vertices that belong together, along with the necessary information for rendering it (especially the indices and the names of the textures used). In XNALara, it corresponds to a MeshDesc.
 */
@objc class GLLModelMesh: NSObject {
    // For subclasses
    @objc init(asPartOfModel model: GLLModel) {
        super.init()
        self.model = model
    }
    
    init(fromStream stream: TRInDataStream, partOfModel model: GLLModel, versionCode: Int) throws {
        self.versionCode = versionCode
        super.init()
        self.model = model
        
        name = stream.readPascalString()
        countOfUVLayers = Int(stream.readUint32())
        
        let meshParams = model.parameters.params(forMesh: name)
        let textureIdentifiers = meshParams.xnaLaraShaderData?.textureUniformsInOrder
        
        let numTextures = Int(stream.readUint32())
        for i in 0..<numTextures {
            let textureName = stream.readPascalString()
            stream.readUint32() // UV layer. Ignored; the shader always has the UV layer for the texture hardcoded.
            guard let finalPathComponent = textureName?.components(separatedBy: "\\").last else {
                throw NSError()
            }
            
            if let identifiers = textureIdentifiers, i < identifiers.count {
                let identifier = identifiers[Int(i)]
                guard let urlPath = finalPathComponent.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
                    throw NSError()
                }
                guard let textureUrl = URL(string: urlPath, relativeTo: model.baseURL) else {
                    throw NSError()
                }
                let textureDescription = model.parameters.description(forTexture: identifier)
                textures[identifier] = GLLTextureAssignment(url: textureUrl, texCoordSet: textureDescription.xnaLaraTexCoordSet)
            }
        }
        
        guard stream.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [ NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),                                                                                                             NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file breaks off during the descriptions of a mesh. Maybe it is damaged?", comment: "Premature end of file error") ])
        }
        
        countOfVertices = Int(stream.readUint32())
        let fileVertexFormat = self.fileVertexFormat
        guard let vertexData = stream.data(withLength: countOfVertices * fileVertexFormat.stride) else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [ NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                                                                                                                           NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The vertex data for a mesh could not be loaded.", comment: "Premature end of file error") ])
        }
        
        countOfElements = 3 * Int(stream.readUint32())
        guard let elementData = stream.data(withLength: countOfElements * 4) else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [ NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),                                                                                                             NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file breaks off inside a mesh's vertex data.", comment: "Premature end of file error") ])
        }
        self.elementData = elementData
        
        // Prepare the vertex data
        let fileAccessors = accessors(forFile: vertexData, format: fileVertexFormat)
        
        try validate(vertexData: fileAccessors, indexData: elementData)
        
        if hasTangentsInFile {
            vertexDataAccessors = fileAccessors
        } else {
            let tangents = calculateTangents(for: fileAccessors)
            vertexDataAccessors = fileAccessors.combining(with: tangents)
        }
        vertexFormat = vertexDataAccessors!.vertexFormat(vertexCount: countOfVertices, hasIndices: true)
        loadRenderParameters()
    }
    
    init(fromScanner scanner: GLLASCIIScanner, partOfModel model: GLLModel) throws {
        super.init()
        self.model = model
        
        name = scanner.readPascalString()
        countOfUVLayers = Int(scanner.readUint32())
        
        let meshParams = model.parameters.params(forMesh: name)
        let textureIdentifiers = meshParams.xnaLaraShaderData?.textureUniformsInOrder
        
        let numTextures = Int(scanner.readUint32())
        for i in 0..<numTextures {
            let textureName = scanner.readPascalString()
            scanner.readUint32() // UV layer. Ignored; the shader always has the UV layer for the texture hardcoded.
            guard let finalPathComponent = textureName?.components(separatedBy: "\\").last else {
                throw NSError()
            }
            
            if let identifiers = textureIdentifiers, i < identifiers.count {
                let identifier = identifiers[Int(i)]
                guard let urlPath = finalPathComponent.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
                    throw NSError()
                }
                guard let textureUrl = URL(string: urlPath, relativeTo: model.baseURL) else {
                    throw NSError()
                }
                let textureDescription = model.parameters.description(forTexture: identifier)
                textures[identifier] = GLLTextureAssignment(url: textureUrl, texCoordSet: textureDescription.xnaLaraTexCoordSet)
            }
        }
        
        countOfVertices = Int(scanner.readUint32())
        
        // Create vertex format
        let fileVertexFormat = self.fileVertexFormat
        var vertexData = Data(capacity: countOfVertices * Int(fileVertexFormat.stride))
        for _ in 0..<countOfVertices {
            // Vertices + normals
            for _ in 0..<6 {
                let value = scanner.readFloat32()
                vertexData.append(value)
            }
            // Color
            for _ in 0..<4 {
                let value = scanner.readUint8()
                vertexData.append(value)
            }
            // Tex coords
            for _ in 0..<2*countOfUVLayers {
                let value = scanner.readFloat32()
                vertexData.append(value)
            }
            // Leave space for tangents
            for _ in 0..<4*countOfUVLayers {
                vertexData.append(Float32(0))
            }
            
            if hasBoneWeights {
                // Bone indices
                var readBoneIndices = 0
                for _ in 0..<4 {
                    let value = scanner.readUint16()
                    _ = Swift.withUnsafeBytes(of: value) {
                        vertexData.append(contentsOf: $0)
                    }
                    readBoneIndices += 1
                    
                    // Some .mesh.ascii files have fewer bones and weights
                    if scanner.hasNewline() {
                        break
                    }
                }
                for _ in readBoneIndices..<4 {
                    let value = UInt16(0)
                    _ = Swift.withUnsafeBytes(of: value) {
                        vertexData.append(contentsOf: $0)
                    }
                }
                
                // Bone weights
                var boneWeights: [Float32] = []
                for _ in 0..<4 {
                    boneWeights.append(scanner.readFloat32())
                    
                    // Some .mesh.ascii files have fewer bones and weights
                    if scanner.hasNewline() {
                        break
                    }
                }
                while boneWeights.count < 4 {
                    boneWeights.append(Float32(0))
                }
                
                let sum = boneWeights.reduce(Float32(0)) { $0 + $1 }
                if sum == Float32(0) {
                    // Someone screwed up
                    boneWeights[0] = 1
                    boneWeights[1] = 0
                    boneWeights[2] = 0
                    boneWeights[3] = 0
                } else {
                    for i in 0..<4 {
                        boneWeights[i] /= sum
                    }
                }
                
                for weight in boneWeights {
                    vertexData.append(weight)
                }
            }
        }
        
        countOfElements = 3 * Int(scanner.readUint32()) // File saves number of triangles
        elementData = Data(capacity: 4 * countOfElements)
        for _ in 0..<countOfElements {
            let element = scanner.readUint32()
            _ = Swift.withUnsafeBytes(of: element) {
                elementData!.append(contentsOf: $0)
            }
        }
        
        // Prepare the vertex data
        let fileAccessors = accessors(forFile: vertexData, format: fileVertexFormat)
        
        try validate(vertexData: fileAccessors, indexData: elementData!)
        
        let tangents = calculateTangents(for: fileAccessors)
        vertexDataAccessors = fileAccessors.combining(with: tangents)
        vertexFormat = vertexDataAccessors!.vertexFormat(vertexCount: countOfVertices, hasIndices: true)
        
        guard scanner.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_PrematureEndOfFile.rawValue), userInfo: [ NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                                                                                                                           NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file breaks off in the middle of the meshes section. Maybe it is damaged?", comment: "Premature end of file error") ])
        }
        
        loadRenderParameters()
    }
    
    @objc weak var model: GLLModel?
    @objc var name: String = ""
    @objc var displayName: String = ""
    @objc var textures: [String: GLLTextureAssignment] = [:]
    @objc var initiallyVisible: Bool = true
    @objc var optionalPartNames: [String] = []
    @objc var meshIndex: Int {
        return model!.meshes.firstIndex(of: self)!
    }
    
    var versionCode: Int = 0
    
    /*
     * Vertex buffer
     */
    @objc var countOfVertices: Int = 0
    @objc var vertexDataAccessors: GLLVertexAttribAccessorSet?
    
    var vertexFormat: GLLVertexFormat?
    
    // Element data. Arranged as triangles, often but not necessarily UInt32
    @objc var elementData: Data?
    @objc var elementSize: Int = 4
    @objc var countOfElements: Int = 0
    
    // Returns the element fo the index. If there is no element buffer (i.e. directly), returns its index
    @objc func element(at index: Int) -> Int {
        guard let elementData = elementData else {
            return index
        }
        switch elementSize {
        case 1:
            return try! Int(elementData.readUInt8(at: index * 1))
        case 2:
            return try! Int(elementData.readUInt16(at: index * 2))
        case 4:
            return try! Int(elementData.readUInt32(at: index * 4))
        default:
            assertionFailure("Unknown element component type")
            return 0
        }
    }
    
    // Returns the count of indices you can use with elementAt - that is either the number of elements, if there is an element buffer, or the number of vertices if drawing directly without one
    @objc var countOfUsedElements: Int {
        if elementData == nil {
            return countOfVertices
        }
        return countOfElements
    }
    
    var countOfUVLayers: Int = 0
    var hasBoneWeights: Bool {
        return self.model?.hasBones ?? false
    }
    var hasTangentsInFile: Bool {
        return versionCode < 3
    }
    private var hasVariableBonesPerVertex: Bool {
        return versionCode >= 4
    }
    var colorsAreFloats: Bool {
        // For subclasses to override
        return false
    }
    
    /*
     * XNALara insists that some meshes need to be split; apparently only for cosmetic reasons. I shall oblige, but in a way that is not specific to exactly one thing, thank you very much. Note that this mesh keeps the bone indices of the original.
     */
    func partialMesh(fromSplitter splitter: GLLMeshSplitter) -> GLLModelMesh {
        var newElements = Data()
        
        let positionData = vertexDataAccessors!.accessor(semantic: .position)!
        
        for triangle in 0..<(countOfUsedElements/3) {
            let index = triangle * 3
            
            let elements = [
                element(at: index + 0),
                element(at: index + 1),
                element(at: index + 2)
            ]
            let position = [
                positionData.typedElementArray(at: elements[0], type: Float32.self),
                positionData.typedElementArray(at: elements[1], type: Float32.self),
                positionData.typedElementArray(at: elements[2], type: Float32.self)
            ]
            
            // Find out if one corner is completely in the box. If yes, then this triangle becomes part of the split mesh.
            var anyCornerInBox = false
            for corner in 0..<3 {
                var allCoordsInBox = true
                for coord in 0..<3 {
                    let cornerPositionAtCoord = Double(position[corner][coord])
                    allCoordsInBox = allCoordsInBox && cornerPositionAtCoord >= splitter.min[coord] && cornerPositionAtCoord <= splitter.max[coord]
                }
                if allCoordsInBox {
                    anyCornerInBox = true
                }
            }
            
            if !anyCornerInBox {
                continue
            }
            
            for corner in 0..<3 {
                let index = UInt32(elements[corner])
                _ = Swift.withUnsafeBytes(of: index) {
                    newElements.append(contentsOf: $0)
                }
            }
        }
        
        let result = GLLModelMesh(asPartOfModel: model!)
        result.vertexFormat = vertexFormat
        result.vertexDataAccessors = vertexDataAccessors
        result.countOfVertices = countOfVertices
        result.elementData = newElements
        result.countOfElements = newElements.count / 4
        
        result.countOfUVLayers = countOfUVLayers
        result.name = splitter.splitPartName
        result.textures = self.textures
        result.loadRenderParameters() // Result may have different mesh group or shader. In fact, for the one and only object class where this entire feature is needed, this is guaranteed.
        return result
    }
    
    /*
     * Drawing information, gained through the model parameters. This information is not stored in the mesh file.
     */
    @objc var shader: GLLShaderData?
    @objc var usesAlphaBlending: Bool = false
    @objc var renderParameterValues: [String: AnyObject] = [:]
    
    private static func normalize(_ array: inout [Float32], from: Int = 0) {
        let lengthSquared = array[from + 0] * array[from + 0] + array[from + 1] * array[from + 1] + array[from + 2] * array[from + 2]
        let inverseLength = 1.0/sqrt(lengthSquared)
        array[from + 0] *= inverseLength
        array[from + 1] *= inverseLength
        array[from + 2] *= inverseLength
    }
    
    // -- For subclasses
    // Calculates the tangents based on the texture coordinates, and fills them in the correct fields of the data, using the offsets and strides of the file
    func calculateTangents(for vertexData: GLLVertexAttribAccessorSet) -> GLLVertexAttribAccessorSet {
        let positionData = vertexData.accessor(semantic: .position)!
        let normalData = vertexData.accessor(semantic: .normal)!
        var result: [GLLVertexAttribAccessor] = []
        for layer in 0..<self.countOfUVLayers {
            let texCoordData = vertexData.accessor(semantic: .texCoord0, layer: layer)!
            
            var tangents = Array(repeating: Float32(0), count: countOfVertices * 4)
            var tangentsU = Array(repeating: Float32(0), count: countOfVertices * 3)
            var tangentsV = Array(repeating: Float32(0), count: countOfVertices * 3)
            
            // First pass: Sum up the tangents for each vector. We can assume that at the start of this method, the tangent for every vertex is (0, 0, 0, 0)^t.
            for triangle in 0..<countOfUsedElements/3 {
                let index = triangle * 3
                let elements = [
                    element(at: index + 0),
                    element(at: index + 1),
                    element(at: index + 2)
                ]
                let positions = [
                    positionData.typedElementArray(at: elements[0], type: Float32.self),
                    positionData.typedElementArray(at: elements[1], type: Float32.self),
                    positionData.typedElementArray(at: elements[2], type: Float32.self)
                ]
                let texCoords = [
                    texCoordData.typedElementArray(at: elements[0], type: Float32.self),
                    texCoordData.typedElementArray(at: elements[1], type: Float32.self),
                    texCoordData.typedElementArray(at: elements[2], type: Float32.self)
                ]
                
                // Calculate tangents
                let q1 = [ positions[1][0] - positions[0][0], positions[1][1] - positions[0][1], positions[1][2] - positions[0][2] ]
                let q2 = [ positions[1][0] - positions[0][0], positions[1][1] - positions[0][1], positions[1][2] - positions[0][2] ]
                
                let s1 = texCoords[1][0] - texCoords[0][0]
                let t1 = texCoords[1][1] - texCoords[0][1]
                let s2 = texCoords[2][0] - texCoords[0][0]
                let t2 = texCoords[2][1] - texCoords[0][1]
                let d = s1 * t2 - s2 * t1
                if (d == 0) {
                    continue
                }
                
                var tangentU = [
                    (t2 * q1[0] - t1 * q2[0]) / d,
                    (t2 * q1[1] - t1 * q2[1]) / d,
                    (t2 * q1[2] - t1 * q2[2]) / d
                ]
                GLLModelMesh.normalize(&tangentU)
                var tangentV = [
                    (s2 * q2[0] - s1 * q1[0]) / d,
                    (s2 * q2[1] - s1 * q1[1]) / d,
                    (s2 * q2[2] - s1 * q1[2]) / d,
                ]
                GLLModelMesh.normalize(&tangentV)
                
                // Add them to the per-layer tangents
                for vertex in 0..<3 {
                    for coord in 0..<3 {
                        tangentsU[elements[vertex] * 3 + coord] += tangentU[coord]
                        tangentsV[elements[vertex] * 3 + coord] += tangentV[coord]
                    }
                }
            }
            
            for vertex in 0..<countOfVertices {
                GLLModelMesh.normalize(&tangentsU, from: vertex*3)
                GLLModelMesh.normalize(&tangentsV, from: vertex*3)
                let normal = normalData.typedElementArray(at: vertex, type: Float32.self)
                let normalDotTangentU = normal[0] * tangentsU[vertex*3 + 0] + normal[1] * tangentsU[vertex*3 + 1] + normal[2] * tangentsU[vertex*3 + 2]
                var tangent = [
                    tangentsU[vertex*3 + 0] - normal[0] * normalDotTangentU,
                    tangentsU[vertex*3 + 1] - normal[1] * normalDotTangentU,
                    tangentsU[vertex*3 + 2] - normal[2] * normalDotTangentU
                ]
                GLLModelMesh.normalize(&tangent)
                
                let w = tangentsV[vertex*3 + 0] * (normal[1] * tangentsU[vertex*3 + 2] - normal[2] * tangentsU[vertex*3 + 1]) +
                tangentsV[vertex*3 + 1] * (normal[2] * tangentsU[vertex*3 + 0] - normal[0] * tangentsU[vertex*3 + 2]) +
                tangentsV[vertex*3 + 2] * (normal[0] * tangentsU[vertex*3 + 1] - normal[1] * tangentsU[vertex*3 + 0])
                
                tangents[vertex*4 + 0] = tangent[0]
                tangents[vertex*4 + 1] = tangent[1]
                tangents[vertex*4 + 2] = tangent[2]
                tangents[vertex*4 + 3] = w > 0 ? 1 : -1
            }
            
            let tangentData = tangents.withUnsafeBufferPointer {
                Data(buffer: $0)
            }
            let attribute = GLLVertexAttrib(semantic: .tangent0, layer: layer, format: .float4)
            result.append(GLLVertexAttribAccessor(attribute: attribute, dataBuffer: tangentData, offset: 0, stride: Int(attribute.sizeInBytes)))
        }
        return GLLVertexAttribAccessorSet(accessors: result)
    }
    
    // Checks whether all the data is valid and can be used. Should be done before calculateTangents:!
    func validate(vertexData: GLLVertexAttribAccessorSet, indexData: Data?) throws {
        // Check bone indices
        if let boneIndexData = vertexData.accessor(semantic: .boneIndices) {
            for i in 0..<countOfVertices {
                let indices = boneIndexData.typedElementArray(at: i, type: UInt16.self)
                for j in 0..<4 {
                    if indices[j] >= model!.bones.count {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_IndexOutOfRange.rawValue), userInfo: [ NSLocalizedDescriptionKey : NSLocalizedString("The file references bones that do not exist.", comment: "Bone index out of range error"),
                                                                                                                                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("An index in the bone references is out of range", comment: "Bone index out of range error") ])
                    }
                }
            }
        }
        
        // Check element indices
        if let indexData = indexData {
            _ = try indexData.withUnsafeBytes { data in
                let indices = data.bindMemory(to: UInt32.self)
                for i in 0..<countOfElements {
                    if indices[i] >= countOfVertices {
                        throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingError_IndexOutOfRange.rawValue), userInfo: [ NSLocalizedDescriptionKey : NSLocalizedString("A mesh references vertices that do not exist.", comment: "Vertex index out of range error"),
                                                                                                                                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("AAn index in the graphics data is out of range", comment: "Vertex index out of range error") ])
                    }
                }
            }
        }
    }
    
    @objc var cullFaceMode: GLLCullFaceMode  {
        return .counterClockWise
    }
    
    @objc func writeAscii(withName name: String, texture textures: [URL]) -> String {
        let positionAccessor = vertexDataAccessors!.accessor(semantic: .position)!
        let normalAccessor = vertexDataAccessors!.accessor(semantic: .normal)!
        let colorAccessor = vertexDataAccessors!.accessor(semantic: .color)!
        let boneIndexAccessor = vertexDataAccessors!.accessor(semantic: .boneIndices)
        let boneWeightAccessor = vertexDataAccessors!.accessor(semantic: .boneWeights)
        
        var result = ""
        result.append("\(name)\n")
        result.append("\(countOfUVLayers)\n")
        result.append("\(textures.count)\n")
        for texture in textures {
            result.append("\(texture.lastPathComponent)\n0\n")
        }
        
        result.append("\(countOfVertices)")
        for i in 0..<countOfVertices {
            let position = positionAccessor.typedElementArray(at: i, type: Float32.self)
            result.append("\(position[0]) \(position[1]) \(position[2])\n")
            let normal = normalAccessor.typedElementArray(at: i, type: Float32.self)
            result.append("\(normal[0]) \(normal[1]) \(normal[2])\n")
            let colors = colorAccessor.typedElementArray(at: i, type: UInt8.self)
            result.append("\(colors[0]) \(colors[1]) \(colors[2]) \(colors[3])\n")
            
            for uvLayer in 0..<countOfUVLayers {
                let texCoordAccessor = vertexDataAccessors!.accessor(semantic: .texCoord0, layer: uvLayer)!
                
                let texCoords = texCoordAccessor.typedElementArray(at: uvLayer, type: Float32.self)
                result.append("\(texCoords[0]) \(texCoords[1])\n")
            }
            if hasBoneWeights {
                let boneIndices = boneIndexAccessor!.typedElementArray(at: i, type: UInt16.self)
                result.append("\(boneIndices[0]) \(boneIndices[1]) \(boneIndices[2]) \(boneIndices[3])\n")
                let boneWeights = boneWeightAccessor!.typedElementArray(at: i, type: Float32.self)
                result.append("\(boneWeights[0]) \(boneWeights[1]) \(boneWeights[2]) \(boneWeights[3])\n")
            }
            result.append("\n")
        }
        
        result.append("\(countOfUsedElements/3)\n")
        for i in 0..<countOfUsedElements {
            result.append("\(element(at: i))")
        }
        result.append("\n")
        
        return result
    }
    @objc func writeBinary(withName name: String, texture textures: [URL]) -> Data {
        let stream = TROutDataStream()
        stream.appendPascalString(name)
        stream.appendUint32(UInt32(countOfUVLayers))
        stream.appendUint32(UInt32(textures.count))
        
        for texture in textures {
            stream.appendPascalString(texture.lastPathComponent)
            stream.appendUint32(0)
        }
        
        stream.appendUint32(UInt32(countOfVertices))
        if hasTangentsInFile {
            // Just put it out directly
            stream.appendData(vertexDataAccessors!.accessors.first!.dataBuffer)
        } else {
            // Long way round: Combine all the elements, no matter where they're from
            let positionData = vertexDataAccessors!.accessor(semantic: .position)!
            let normalData = vertexDataAccessors!.accessor(semantic: .normal)!
            let colorData = vertexDataAccessors!.accessor(semantic: .color)!
            let boneIndexData = vertexDataAccessors!.accessor(semantic: .boneIndices)
            let boneWeightData = vertexDataAccessors!.accessor(semantic: .boneWeights)

            for i in 0..<countOfVertices {
                stream.appendData(positionData.elementData(at: i))
                stream.appendData(positionData.elementData(at: i))
                stream.appendData(normalData.elementData(at: i))
                stream.appendData(colorData.elementData(at: i))
                for layer in 0..<countOfUVLayers {
                    let texCoordData = vertexDataAccessors!.accessor(semantic: .texCoord0, layer:layer)!
                    stream.appendData(texCoordData.elementData(at: i))
                }
                for layer in 0..<countOfUVLayers {
                    let tangentData = vertexDataAccessors!.accessor(semantic: .tangent0, layer:layer)!
                    stream.appendData(tangentData.elementData(at: i))
                }
                if let boneIndexData = boneIndexData, let boneWeightData = boneWeightData {
                    stream.appendData(boneIndexData.elementData(at: i))
                    stream.appendData(boneWeightData.elementData(at: i))
                }
            }
        }
        stream.appendUint32(UInt32(countOfUsedElements/3))
        for i in 0..<countOfUsedElements {
            stream.appendUint32(UInt32(element(at: i)))
        }
        return stream.data()
    }
    
    // Finalize loading. In particular, load render parameters.
    private func loadRenderParameters() {
        let meshParams = model!.parameters.params(forMesh: name)
        usesAlphaBlending = meshParams.transparent
        displayName = meshParams.displayName
        initiallyVisible = meshParams.visible
        optionalPartNames = meshParams.optionalPartNames
        for param in meshParams.renderParameters {
            renderParameterValues[param.key] = param.value as AnyObject
        }
        guard let xnaLaraShaderData = meshParams.xnaLaraShaderData else {
            print("No shader for \(name)")
            return
        }
        shader = model!.parameters.shader(xnaData: xnaLaraShaderData, vertexAccessors: vertexDataAccessors!, alphaBlending: usesAlphaBlending)
        
        if shader == nil {
            print("No shader for \(name)")
        }
    }
    
    // The vertex format for the things that are in the file
    private var fileVertexFormat: GLLVertexFormat {
        var attributes: [GLLVertexAttrib] = []
        attributes.append(GLLVertexAttrib(semantic: .position, layer: 0, format: .float3))
        attributes.append(GLLVertexAttrib(semantic: .normal, layer: 0, format: .float3))
        attributes.append(GLLVertexAttrib(semantic: .color, layer: 0, format: colorsAreFloats ? .float4 : .uchar4Normalized))
        for i in 0..<countOfUVLayers {
            attributes.append(GLLVertexAttrib(semantic: .texCoord0, layer: i, format: .float2))
        }
        if hasTangentsInFile {
            for i in 0..<countOfUVLayers {
                attributes.append(GLLVertexAttrib(semantic: .tangent0, layer: i, format: .float4))
            }
        } else if hasVariableBonesPerVertex {
            // TODO implement this properly
            attributes.append(GLLVertexAttrib(semantic: .padding, layer: 0, format: .ushort))
        }
        if hasBoneWeights {
            attributes.append(GLLVertexAttrib(semantic: .boneIndices, layer: 0, format: .ushort4))
            attributes.append(GLLVertexAttrib(semantic: .boneWeights, layer: 0, format: .float4))
        }
        
        return GLLVertexFormat(attributes: attributes, countOfVertices: 0, hasIndices: true)
    }

    // Generates the vertex data accessors for exactly those things that are in the file.
    // Things that get calculated later, in particular tangents, get added later.
    private func accessors(forFile baseData: Data, format fileVertexFormat: GLLVertexFormat) -> GLLVertexAttribAccessorSet {
        let stride = fileVertexFormat.stride
        
        var offset = 0
        var accessors: [GLLVertexAttribAccessor]  = []
        for attribute in fileVertexFormat.attributes {
            accessors.append(GLLVertexAttribAccessor(attribute: attribute, dataBuffer: baseData, offset: offset, stride: stride))
            offset += Int(attribute.sizeInBytes)
        }
        
        return GLLVertexAttribAccessorSet(accessors: accessors)
    }
}
