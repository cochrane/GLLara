//
//  GLLModelXNALara.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

class GLLModelXNALara: GLLModel {
    convenience init(binaryFromFile file: URL!, parent: GLLModel!) throws {
        let data = try Data(contentsOf: file, options: .mappedIfSafe)
        try self.init(binaryFrom: data, baseURL: file, parent: parent)
    }
    
    init(binaryFrom data: Data!, baseURL: URL!, parent: GLLModel?) throws {
        super.init()
        
        guard data.count >= 2 else {
            // Minimum length
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is shorter than the minimum file size.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("A model has to be at least eight bytes long. This file may be corrupted.", comment: "Premature end of file error.")
            ])
        }
        
        self.baseURL = baseURL
        parameters = try GLLModelParams.parameters(forModel: self)
        
        let stream = TRInDataStream(data: data)
        let genericItemVersion: Int
        var header = stream.readUint32()
        if header == 323232 {
            /*
             * This is my idea of how to support the Generic Item 2 format. Note
             * that this is all reverse engineered from looking at files. I do not
             * know whether my variable names are correct, and I do not interpret
             * it in any way.
             */
            
            // First: Two uint16s. My guess: Major, then minor version.
            let majorVersion = stream.readUint16()
            let minorVersion = stream.readUint16()
            print("Versions: \(majorVersion).\(minorVersion)")
            if majorVersion == 1 {
                genericItemVersion = 2
            } else if majorVersion == 2 {
                genericItemVersion = 3
            } else if majorVersion == 3 {
                genericItemVersion = 4
            } else {
                throw NSError(domain: "GLLModel", code: 10, userInfo: [
                    NSLocalizedDescriptionKey : NSLocalizedString("New-style Generic Item has unknown major version.", comment: "Generic Item 2: Second uint32 unexpected"),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("If there is a .mesh.ascii version, try opening that.", comment: "New-style binary generic item won't work.")
                ])
            }
            
            // A string. In all files that I've seen it is XNAaraL.
            let toolAuthor = stream.readPascalString()
            if toolAuthor != "XNAaraL" {
                print("Unusual tool author string at \(stream.position): \(String(describing: toolAuthor))")
            }
            
            // A count of… thingies that appear after the next three strings. Skip that count times four bytes and you are ready to read bones.
            let countOfUnknownInts = stream.readUint32()
            
            // These strings don't do anything, they just leak machine names and paths of whoever created the model file
            let firstAuxiliaryString = stream.readPascalString()
            let secondAuxiliaryString = stream.readPascalString()
            let thirdAuxiliaryString = stream.readPascalString()
            print("Auxiliary strings: \(firstAuxiliaryString) \(secondAuxiliaryString) \(thirdAuxiliaryString)")
            
            // The thingies from above. All the same value in the models I've seen so far, typically small integers (0 or 3). Not sure what count relates to; is not bone count, mesh count, bone count + mesh count or anything like that.
            stream.skip(bytes: 4 * Int(countOfUnknownInts))
            
            // Now read number of bones
            header = stream.readUint32()
        } else {
            genericItemVersion = 0
        }
        
        let numBones = header
        guard numBones * 15 <= stream.levelData.count - Int(stream.position) else { // Sanity check
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file cannot contain as many bones as it claims.", comment: "numBones too large error (short description)"),
                NSLocalizedRecoverySuggestionErrorKey : String(format: NSLocalizedString("The file declares that it contains %lu bones, but it is shorter than the minimum size required to store all of them. This can happen if a file in the ASCII format is read as Binary.", comment: "numBones too large error (long description)"), numBones)
            ])
        }
        
        bones = try (0..<numBones).map { _ in try GLLModelBone(sequentialData: stream) }
        try assignBoneChildren()
        
        guard stream.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file contains only bones and no meshes. Maybe it was damaged?", comment: "Premature end of file error.")
            ])
        }
        
        let numMeshes = Int(stream.readUint32())
        let unprocessedMeshes = try (0 ..< numMeshes).map { _ in
            try GLLModelMesh(fromStream: stream, partOfModel: self, versionCode: genericItemVersion)
        }
        
        try throwingRunAndBlock {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for mesh in unprocessedMeshes {
                    group.addTask {
                        try mesh.finishProcessing()
                    }
                }
                try await group.waitForAll()
            }
        }
        
        var splitMeshes: [GLLModelMesh] = []
        splitMeshes.reserveCapacity(unprocessedMeshes.count)
        for mesh in unprocessedMeshes {
            let params = self.parameters.params(forMesh: mesh.name)
            if params.splitters.isEmpty {
                splitMeshes.append(mesh)
            } else {
                splitMeshes.append(contentsOf: params.splitters.map { mesh.partialMesh(fromSplitter: $0) })
            }
        }
        self.meshes = splitMeshes
        
        guard stream.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The mesh data is incomplete. The file may be damaged.", comment: "Premature end of file error.")
            ])
        }
        
        // Ignore the trailing data. XNALara writes some metadata there that varies depending on the version, but doesn't seem to be actually necessary for anything (famous last words…?)
    }
    
    convenience init(ASCIIFromFile file: URL!, parent: GLLModel?) throws {
        var encoding: String.Encoding = .utf8
        let source = try String(contentsOf: file, usedEncoding: &encoding)
        try self.init(asciiFrom: source, baseURL: file, parent: parent)
    }
    
    init(asciiFrom string: String, baseURL: URL, parent: GLLModel?) throws {
        super.init()
        
        self.baseURL = baseURL
        self.parameters = try GLLModelParams.parameters(forModel: self)
        
        let scanner = GLLASCIIScanner(string: string)
        let numBones = scanner.readUint32()
        var bones: [GLLModelBone] = []
        for _ in 0..<numBones {
            let bone = try GLLModelBone(sequentialData: scanner)
            
            // Check whether parent has this bone and defer to it instead
            if let boneInParent = parent?.bone(name: bone.name) {
                bones.append(boneInParent)
            } else {
                bones.append(bone)
            }
        }
        self.bones = bones
        try assignBoneChildren()
        
        guard scanner.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file contains only bones and no meshes. Maybe it was damaged?", comment: "Premature end of file error.")
            ])
        }
        
        let numMeshes = scanner.readUint32()
        var meshes: [GLLModelMesh] = []
        for _ in 0..<numMeshes {
            let mesh = try GLLModelMesh(fromScanner: scanner, partOfModel: self)
            let params = self.parameters.params(forMesh: mesh.name)
            if params.splitters.isEmpty {
                meshes.append(mesh)
            } else {
                meshes.append(contentsOf: params.splitters.map { mesh.partialMesh(fromSplitter: $0) })
            }
        }
        self.meshes = meshes
        
        guard scanner.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The mesh data is incomplete. The file may be damaged.", comment: "Premature end of file error.")
            ])
        }
    }
    
    func assignBoneChildren() throws {
        for i in 0 ..< bones.count {
            let bone = bones[i]
            if Int(bone.parentIndex) < 0 {
                continue
            }
            if Int(bone.parentIndex) == i {
                // Apparently that's a thing that people do. Create unused bones with themselves set as parent. Why, though?
                if bone.name.hasPrefix("unused") {
                    print("Bone \(i) (named \(bone.name) has itself as parent. Unused, so treated as root bone.")
                    continue
                } else {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.indexOutOfRange.rawValue), userInfo: [
                        NSLocalizedDescriptionKey : String(format:NSLocalizedString("Bone \"%@\" has itself as an ancestor.", comment: "Found a circle in the bone relationships."), bone.name),
                        NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The bones would form an infinite loop.", comment: "Found a circle in a bone relationship")])
                }
            }
            if Int(bone.parentIndex) >= bones.count {
                throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.indexOutOfRange.rawValue), userInfo: [
                    NSLocalizedDescriptionKey : String(format:NSLocalizedString("Parent of bone \"%@\" does not exist.", comment: "The parent index of this bone is invalid."), bone.name),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("All bones have to have a parent that exists or no parent at all.", comment: "The parent index of this bone is invalid.")])
            }
            let parent = bones[Int(bone.parentIndex)]
            bone.parent = parent
            parent.children.append(bone)
        }
        
        for bone in bones {
            var ancestor: GLLModelBone? = bone.parent
            while ancestor != nil {
                if ancestor == bone {
                    throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.circularReference.rawValue), userInfo: [
                        NSLocalizedDescriptionKey : String(format:NSLocalizedString("Bone \"%@\" has itself as an ancestor.", comment: "Found a circle in the bone relationships."), bone.name),
                        NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The bones would form an infinite loop.", comment: "Found a circle in a bone relationship")])
                }
                ancestor = ancestor?.parent
            }
        }
    }
}
