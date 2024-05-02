//
//  ObjFile.swift
//  GLLara
//
//  Created by Torsten Kammer on 01.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//

import Foundation

/***
 * A fairly normal OBJ loader, extended for XNALara compatibilitiy.
 *
 * This has been updated to support colors
 */
struct ObjFile {
    
    struct VertexData {
        var vert = SIMD3<Float32>()
        var norm = SIMD3<Float32>()
        var color = SIMD4<Float32>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
        var tex = SIMD2<Float32>()
    }
    
    struct MaterialRange {
        var start: Int
        var end: Int
        var materialName: String
    }
    
    // Vertex data as saved in the OBJ-file.
    private var vertices: [SIMD3<Float32>] = []
    private var normals: [SIMD3<Float32>] = []
    private var texCoords: [SIMD2<Float32>] = []
    private var colors: [SIMD4<Float32>] = []
    
    // Indices as saved in the OBJ-file.
    struct IndexSet: Hashable {
        var vertex: Int = -1
        var normal: Int? = nil
        var texCoord: Int? = nil
        var color: Int? = nil // Color is an XNA-Lara extension
    }
    private var originalIndices: [IndexSet] = []
    
    // Mapping from a/b/c to single indices
    private var vertexDataForIndexSet: [IndexSet: Int] = [:]
    
    // Vertex buffer, used by OpenGL
    var vertexData: [VertexData] = []
    
    // Index buffers, used by OpenGL
    var indices: [Int] = []
    
    // Support for material handling.
    var materialRanges: [MaterialRange] = []
    var materialLibraries: [URL] = []
    
    private class ObjDataStream {
        static let LF = UInt8(10)
        static let CR = UInt8(13)
        static let SPACE = UInt8(32)
        static let MINUS = Character("-").asciiValue!
        static let DIGIT_0 = Character("0").asciiValue!
        static let DIGIT_9 = Character("9").asciiValue!
        static let SLASH = Character("/").asciiValue!
        static let LOWERCASE_C = Character("c").asciiValue!
        static let LOWERCASE_F = Character("f").asciiValue!
        static let LOWERCASE_M = Character("m").asciiValue!
        static let LOWERCASE_N = Character("n").asciiValue!
        static let LOWERCASE_U = Character("u").asciiValue!
        static let LOWERCASE_T = Character("t").asciiValue!
        static let LOWERCASE_V = Character("v").asciiValue!
        
        let data: Data
        var currentIndex: Data.Index
        let end: Data.Index
        
        init(data: Data) {
            self.data = data
            self.currentIndex = data.startIndex
            self.end = data.endIndex
            if atEnd {
                current = nil
            } else {
                current = data[currentIndex]
            }
        }
        
        func advance() {
            currentIndex = currentIndex.advanced(by: 1)
            if atEnd {
                current = nil
            } else {
                current = data[currentIndex]
            }
        }
        
        var current: UInt8!
        var atEnd: Bool {
            return currentIndex == end
        }
        
        func has(string: String) -> Bool {
            let view = string.utf8
            var viewIndex = view.startIndex
            while viewIndex < view.endIndex {
                if atEnd || current != view[viewIndex] {
                    return false
                }
                advance()
                viewIndex = view.index(after: viewIndex)
            }
            return true
        }
        
        func skipSpace() {
            while !atEnd && current == ObjDataStream.SPACE {
                advance()
            }
        }
        
        func skipWhitespace() {
            while !atEnd && (current == ObjDataStream.SPACE || current == ObjDataStream.CR || current == ObjDataStream.LF) {
                advance()
            }
        }
        
        func skipToEndOfLine() {
            while !atEnd && current != ObjDataStream.LF && current != ObjDataStream.CR {
                advance()
            }
        }
        
        func stringToEndOfLine() -> String {
            let start = currentIndex
            while !atEnd && current != ObjDataStream.LF && current != ObjDataStream.CR {
                advance()
            }
            return String(data: data[start..<currentIndex], encoding: .windowsCP1252)!
        }
        
        func stringToWhitespace() -> String {
            let start = currentIndex
            while !atEnd && current != ObjDataStream.SPACE && current != ObjDataStream.LF && current != ObjDataStream.CR {
                advance()
            }
            return String(data: data[start..<currentIndex], encoding: .windowsCP1252)!
        }
        
        func parseInt() -> Int {
            var value = 0
            var signum = 1
            while !atEnd && current == ObjDataStream.MINUS {
                signum *= -1
                advance()
            }
            while !atEnd && current >= ObjDataStream.DIGIT_0 && current <= ObjDataStream.DIGIT_9 {
                value = value * 10 + Int(current - ObjDataStream.DIGIT_0)
                advance()
            }
            return signum * value
        }
        
        func parseVector<T: SIMD<Float>>(into values: inout [T]) {
            var value = T()
            for i in 0 ..< value.scalarCount {
                skipSpace()
                
                let string = stringToWhitespace()
                value[i] = Float(string)!
            }
            values.append(value)
        }

    }
    
    private mutating func parseFace(stream: ObjDataStream) {
        stream.advance()
        var indexSets: [IndexSet] = []
        while !stream.atEnd {
            stream.skipSpace()
            
            if stream.atEnd || stream.current == ObjDataStream.CR || stream.current == ObjDataStream.LF {
                break
            }
            
            var set = IndexSet()
            // Scan vertex
            set.vertex = stream.parseInt()
            if stream.atEnd {
                // Invalid
                stream.skipToEndOfLine()
                break
            } else if stream.current == ObjDataStream.SLASH {
                // Standard case: Have tex coord, normal
                stream.advance()
                
                // Scan tex coord
                set.texCoord = stream.parseInt()
                if stream.atEnd || stream.current != ObjDataStream.SLASH {
                    // Invalid
                    stream.skipToEndOfLine()
                    break
                }
                stream.advance()
                
                // Scan normal
                set.normal = stream.parseInt()
                
                // Scan color if present
                if !stream.atEnd && stream.current == ObjDataStream.SLASH {
                    stream.advance()
                    set.color = stream.parseInt()
                }
            } else {
                // Only vertices
                stream.advance()
            }
            
            // Postprocess
            if set.vertex > 0 {
                set.vertex -= 1
            } else {
                set.vertex += vertices.count
            }
            
            if let normal = set.normal {
                if normal > 0 {
                    set.normal = normal - 1
                } else {
                    set.normal = normal + normals.count
                }
            }
            
            if let texCoord = set.texCoord {
                if texCoord > 0 {
                    set.texCoord = texCoord - 1
                } else {
                    set.texCoord = texCoord + texCoords.count
                }
            }
            
            if let color = set.color {
                if color > 0 {
                    set.color = color - 1
                } else {
                    set.color = color + colors.count
                }
            }
            indexSets.append(set)
        }
        
        if indexSets.count < 3 {
            // Invalid
            return
        }
        // Treat the face as a triangle fan. And reverse order while we're at it.
        for i in 2..<indexSets.count {
            originalIndices.append(indexSets[0])
            originalIndices.append(indexSets[i])
            originalIndices.append(indexSets[i-1])
        }
    }
    
    private mutating func unifiedIndex(for set: IndexSet) -> Int {
        if let index = vertexDataForIndexSet.index(forKey: set) {
            return vertexDataForIndexSet[index].value
        }
        var data = VertexData()
        
        data.vert = vertices[set.vertex]
        if let normal = set.normal {
            data.norm = normals[normal]
        }
        if let texCoord = set.texCoord {
            data.tex = texCoords[texCoord]
        }
        if let color = set.color {
            data.color = colors[color]
        }
        let currentCount = vertexData.count
        vertexData.append(data)
        vertexDataForIndexSet[set] = currentCount
        return currentCount
    }
    
    private mutating func fillIndices() {
        for indexSet in originalIndices {
            indices.append(unifiedIndex(for: indexSet))
        }
    }
    
    init(from location: URL) throws {
        let data = try Data(contentsOf: location, options: .mappedIfSafe)
        let stream = ObjDataStream(data: data)
        
        var activeMaterial = ""
        var activeMaterialStart = 0
        var hasFirstMaterial = false
        while !stream.atEnd {
            stream.skipWhitespace()
            if stream.atEnd {
                break
            }
            
            switch stream.current {
            case ObjDataStream.LOWERCASE_F:
                parseFace(stream: stream)
                break
            case ObjDataStream.LOWERCASE_V:
                stream.advance()
                switch stream.current {
                case ObjDataStream.LOWERCASE_N: // Normals
                    stream.advance()
                    stream.parseVector(into: &normals)
                    break
                case ObjDataStream.LOWERCASE_T: // Tex coords
                    stream.advance()
                    stream.parseVector(into: &texCoords)
                    break
                case ObjDataStream.LOWERCASE_C: // Colors
                    stream.advance()
                    stream.parseVector(into: &colors)
                    break
                case ObjDataStream.SPACE: // Vertex
                    stream.advance()
                    stream.parseVector(into: &vertices)
                    break
                default:
                    stream.skipToEndOfLine()
                    break
                }
                break
            case ObjDataStream.LOWERCASE_M:
                if stream.has(string: "mtllib") {
                    let mtllibPath = stream.stringToEndOfLine()
                    materialLibraries.append(objPathUrl(from: mtllibPath, relativeTo: location))
                } else {
                    stream.skipToEndOfLine()
                }
                break
            case ObjDataStream.LOWERCASE_U:
                if stream.has(string: "usemtl") {
                    if hasFirstMaterial {
                        // End previous material run
                        materialRanges.append(MaterialRange(start: activeMaterialStart, end: originalIndices.count, materialName: activeMaterial))
                    } else {
                        hasFirstMaterial = true
                    }
                    
                    stream.advance()
                    activeMaterial = stream.stringToEndOfLine()
                    activeMaterialStart = originalIndices.count
                } else {
                    stream.skipToEndOfLine()
                }
                break
            default:
                stream.skipToEndOfLine()
                break
            }
        }
        
        // Wrap up final material group
        materialRanges.append(MaterialRange(start: activeMaterialStart, end: originalIndices.count, materialName: activeMaterial))
        
        fillIndices()
    }
}

func objPathUrl(from string: String, relativeTo: URL) -> URL {
    var path = string
    // Is this possibly a windows path?
    if try! /[A-Za-z]:\\/.prefixMatch(in: string) != nil {
        // It is! Take only the last component
        let lastBackslash = string.lastIndex(of: Character("\\"))!
        path = String(string[string.index(after: lastBackslash) ..< string.endIndex])
    }
    path = path.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return URL(fileURLWithPath: path, relativeTo: relativeTo)
}
