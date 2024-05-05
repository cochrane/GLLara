//
//  MtlFile.swift
//  GLLara
//
//  Created by Torsten Kammer on 01.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//

import Foundation

class MtlFile {
    struct Material {
        var ambient = SIMD4<Float32>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
        var diffuse = SIMD4<Float32>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
        var specular = SIMD4<Float32>(x: 1.0, y: 1.0, z: 1.0, w: 1.0)
        var shininess: Float = 1.0
        var diffuseTexture: URL? = nil
        var specularTexture: URL? = nil
        var normalTexture: URL? = nil
        var name: String = ""
    }
    
    var materials: [String: Material] = [:]
    
    init(from location: URL) throws {
        let contents = try String(contentsOf: location)
        let scanner = Scanner(string: contents)
        // Use american english at all times, because that is the number format used.
        scanner.locale = Locale(identifier: "en_US")
        var hasFirstMaterial = false
        var currentMaterial = Material()
        
        while !scanner.isAtEnd {
            let token = scanner.scanUpToCharacters(from: CharacterSet.whitespaces)
            if token == "newmtl" {
                if !hasFirstMaterial {
                    // This is the first material. Just save the name.
                    currentMaterial.name = scanner.scanUpToCharacters(from: CharacterSet.newlines) ?? ""
                    hasFirstMaterial = true
                } else {
                    // Old material ends here. Store it here; map copies it, so it can be overwritten now.
                    materials[currentMaterial.name] = currentMaterial
                    currentMaterial = Material()
                    currentMaterial.name = scanner.scanUpToCharacters(from: CharacterSet.newlines) ?? ""
                }
            } else if token == "Ka" {
                currentMaterial.ambient[0] = scanner.scanFloat() ?? 0.0
                if let nextValue = scanner.scanFloat() {
                    currentMaterial.ambient[1] = nextValue
                    currentMaterial.ambient[2] = scanner.scanFloat() ?? 0.0
                } else {
                    currentMaterial.ambient[1] = currentMaterial.ambient[0]
                    currentMaterial.ambient[2] = currentMaterial.ambient[0]
                }
            } else if token == "Kd" {
                currentMaterial.diffuse[0] = scanner.scanFloat() ?? 0.0
                if let nextValue = scanner.scanFloat() {
                    currentMaterial.diffuse[1] = nextValue
                    currentMaterial.diffuse[2] = scanner.scanFloat() ?? 0.0
                } else {
                    currentMaterial.diffuse[1] = currentMaterial.diffuse[0]
                    currentMaterial.diffuse[2] = currentMaterial.diffuse[0]
                }
            } else if token == "Ks" {
                currentMaterial.specular[0] = scanner.scanFloat() ?? 0.0
                if let nextValue = scanner.scanFloat() {
                    currentMaterial.specular[1] = nextValue
                    currentMaterial.specular[2] = scanner.scanFloat() ?? 0.0
                } else {
                    currentMaterial.specular[1] = currentMaterial.specular[0]
                    currentMaterial.specular[2] = currentMaterial.specular[0]
                }
            } else if token == "Ns" {
                currentMaterial.shininess = scanner.scanFloat() ?? 0.0
            } else if token == "map_Kd" {
                currentMaterial.diffuseTexture = objPathUrl(from: scanner.scanUpToCharacters(from: CharacterSet.newlines) ?? "", relativeTo: location)
            } else if token == "map_Ks" {
                currentMaterial.specularTexture = objPathUrl(from: scanner.scanUpToCharacters(from: CharacterSet.newlines) ?? "", relativeTo: location)
            } else if token == "map_Kn" || token == "bump" || token == "map_bump" {
                currentMaterial.normalTexture = objPathUrl(from: scanner.scanUpToCharacters(from: CharacterSet.newlines) ?? "", relativeTo: location)
            } else {
                _ = scanner.scanUpToCharacters(from: CharacterSet.newlines)
            }
            
            _ = scanner.scanCharacters(from: CharacterSet.newlines)
        }
        
        // Wrap up final material
        materials[currentMaterial.name] = currentMaterial;
    }
}
