//
//  GLLModelObj.swift
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

/**
 * A Model read from an OBJ file.
 * These models will always have exactly one bone, and one mesh for
 * every material used. XNALara-specific extensions and simplifications are
 * supported, too.
 */
class GLLModelObj: GLLModel {
    init(contentsOf url: URL) throws {
        
        file = try ObjFile(from: url)
        materialFiles = try file.materialLibraries.map { try MtlFile(from: $0) }
        if materialFiles.count == 0 {
            do {
                materialFiles.append(try MtlFile(from: url.deletingPathExtension().appendingPathExtension("mtl")))
            } catch {
                // Ignore
            }
        }
        
        super.init()
        
        baseURL = url
        
        // 1. Set up bones. We only have the one.
        self.bones = [ GLLModelBone() ]
        
        // 2. Set up meshes. We use one mesh per material group.
        self.meshes = try file.materialRanges.map { range in
            // Procedure: Go through the indices in the range. For each index, load the vertex data from the file and put it in the vertex buffer here. Adjust the index, too.

            var globalToLocalIndices: [Int: UInt32] = [:]
            var vertices = Data(capacity: (range.end - range.start) * MemoryLayout<ObjFile.VertexData>.stride)
            var elementData = Array<UInt32>(repeating: 0, count: range.end - range.start)

            for i in range.start ..< range.end {
                let globalIndex = file.indices[i]
                let localIndexIter = globalToLocalIndices.index(forKey: globalIndex)
                if let localIndexIter {
                    elementData[i - range.start] = globalToLocalIndices[localIndexIter].value
                } else {
                    // Add adjusted element
                    let index = globalToLocalIndices.count
                    elementData[i - range.start] = UInt32(exactly: index)!
                    globalToLocalIndices[globalIndex] = UInt32(index)
                    
                    // Add vertex
                    var vertex = file.vertexData[globalIndex]
                    var texCoordY: Float32 = 1.0 - vertex.tex[1]
                    withUnsafeBytes(of: &vertex) { bytes in
                        let uint8ptr = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                        vertices.append(uint8ptr.advanced(by: MemoryLayout<ObjFile.VertexData>.offset(of: \.vert)!), count: 12)
                        vertices.append(uint8ptr.advanced(by: MemoryLayout<ObjFile.VertexData>.offset(of: \.norm)!), count: 12)
                        vertices.append(uint8ptr.advanced(by: MemoryLayout<ObjFile.VertexData>.offset(of: \.color)!), count: 16)
                        vertices.append(uint8ptr.advanced(by: MemoryLayout<ObjFile.VertexData>.offset(of: \.tex)!), count: 4)
                        withUnsafeBytes(of: &texCoordY) { texCoordYBytes in
                            let texCoordUint8ptr = texCoordYBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                            vertices.append(texCoordUint8ptr, count: 4)
                        }
                        
                        // No bone weights or indices here; OBJs use special shaders that don't use them.
                    }
                }
            }
                
            // Set up vertex attributes
            let fileAccessors = GLLVertexAttribAccessorSet(accessors: [
                GLLVertexAttribAccessor(semantic: .position, format: .float3, dataBuffer: vertices, offset: 0, stride: 48),
                GLLVertexAttribAccessor(semantic: .normal, format: .float3, dataBuffer: vertices, offset: 12, stride: 48),
                GLLVertexAttribAccessor(semantic: .color, format: .float4, dataBuffer: vertices, offset: 24, stride: 48),
                GLLVertexAttribAccessor(semantic: .texCoord0, format: .float2, dataBuffer: vertices, offset: 40, stride: 48)
            ])
            let elementDataWrapped = elementData.withUnsafeMutableBufferPointer {
                Data(buffer: $0)
            }
            
            // Setup material
            var material: MtlFile.Material? = nil
            for materialFile in materialFiles {
                if let foundMaterial = materialFile.materials[range.materialName] {
                    material = foundMaterial
                    break
                }
            }
            var textures: [String: GLLTextureAssignment] = [:]
            var renderParameterValues: [String: AnyObject] = [
                "ambientColor": NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                "diffuseColor": NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                "specularColor": NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                "specularExponent": NSNumber(value: 1.0)
            ]
            if let material = material {
                if let diffuseTexture = material.diffuseTexture {
                    textures["diffuseTexture"] = GLLTextureAssignment(url: diffuseTexture, texCoordSet: 0)
                }
                if let specularTexture = material.specularTexture {
                    textures["specularTexture"] = GLLTextureAssignment(url: specularTexture, texCoordSet: 0)
                }
                if let normalTexture = material.normalTexture {
                    textures["bumpTexture"] = GLLTextureAssignment(url: normalTexture, texCoordSet: 0)
                }
                renderParameterValues["ambientColor"] = NSColor(calibratedRed: CGFloat(material.ambient.x), green: CGFloat(material.ambient.y), blue: CGFloat(material.ambient.z), alpha: CGFloat(material.ambient.w))
                renderParameterValues["diffuseColor"] = NSColor(calibratedRed: CGFloat(material.diffuse.x), green: CGFloat(material.diffuse.y), blue: CGFloat(material.diffuse.z), alpha: CGFloat(material.diffuse.w))
                renderParameterValues["specularColor"] = NSColor(calibratedRed: CGFloat(material.specular.x), green: CGFloat(material.specular.y), blue: CGFloat(material.specular.z), alpha: CGFloat(material.specular.w))
                renderParameterValues["specularExponent"] = NSNumber(value: material.shininess)
            }
            return try GLLModelMeshObj(asPartOfModel: self, fileVertexAccessors: fileAccessors, countOfVertices: globalToLocalIndices.count, elementData: elementDataWrapped, textures: textures, renderParameterValues: renderParameterValues)
        }
        for i in 0 ..< meshes.count {
            meshes[i].displayName = String(format: NSLocalizedString("Mesh %lu", comment: "Mesh name for obj format"), (i + 1))
        }
        
        // 3. Render parameters
        self.parameters = try! GLLModelParams.parameters(forName: "objFileParameters")
    }
    
    let file: ObjFile
    var materialFiles: [MtlFile]
}
