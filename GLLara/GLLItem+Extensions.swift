//
//  GLLItem+Extensions.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//
//

import Foundation

extension GLLItem {
    @objc var rootBones: [GLLItemBone] {
        return bones.filter({
            ($0 as! GLLItemBone).parent == nil
        }).map { $0 as! GLLItemBone }
    }
    
    @objc func itemMesh(for modelMesh: GLLModelMesh) -> GLLItemMesh? {
        return meshes![modelMesh.meshIndex] as? GLLItemMesh
    }
    
    @objc func bone(name: String) -> GLLItemBone? {
        return bones.first(where: { ($0 as! GLLItemBone).bone.name == name }) as? GLLItemBone
    }
    
    @objc var rootItem: GLLItem {
        if let parent {
            return parent.rootItem
        }
        return self
    }
    
    @objc var hasOptionalParts: Bool {
        return meshes?.first(where: { ($0 as! GLLItemMesh).mesh.optionalPartNames.count > 0 }) != nil
    }
    
    @objc func loadPose(url: URL) throws {
        let text = try String(contentsOf: url)
        try loadPose(description: text)
    }
    
    @objc func loadPose(description: String) throws {
        let lines = description.components(separatedBy: CharacterSet.newlines)
        if description.firstIndex(of: ":") == nil {
            // Old-style loading: Same number of lines as bones, sequentally stored, no names.
            if (lines.count != bones.count) {
                throw NSError(domain: "poses", code: 1, userInfo:[
                    NSLocalizedDescriptionKey : NSLocalizedString("Pose file does not contain the right amount of bones", comment: "error loading pose old-style"),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Poses in the old format have to contain exactly as many items as bones. Try using a newer pose.", comment: "error loading pose old-style")]);
            }

            for i in 0 ..< lines.count {
                let scanner = Scanner(string: lines[i])
                if let x = scanner.scanFloat() {
                    (bones[i] as! GLLItemBone).rotationX = x
                }
                if let y = scanner.scanFloat() {
                    (bones[i] as! GLLItemBone).rotationY = y
                }
                if let z = scanner.scanFloat() {
                    (bones[i] as! GLLItemBone).rotationZ = z
                }
            }
        } else {
            for line in lines {
                let scanner = Scanner(string: line)
                guard let name = scanner.scanUpToString(":") else {
                    continue
                }
                _ = scanner.scanString(":")
                guard let bone = bones.first(where: { ($0 as! GLLItemBone).bone.name == name }) as? GLLItemBone else {
                    continue
                }
                if let x = scanner.scanFloat() {
                    bone.rotationX = x * Float.pi / 180.0
                }
                if let y = scanner.scanFloat() {
                    bone.rotationY = y * Float.pi / 180.0
                }
                if let z = scanner.scanFloat() {
                    bone.rotationZ = z * Float.pi / 180.0
                }
                if let x = scanner.scanFloat() {
                    bone.positionX = x
                }
                if let y = scanner.scanFloat() {
                    bone.positionY = y
                }
                if let z = scanner.scanFloat() {
                    bone.positionZ = z
                }
            }
        }
    }
}
