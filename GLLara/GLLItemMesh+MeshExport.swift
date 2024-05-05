//
//  GLLItemMesh+MeshExport.swift
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItemMesh {
    
    private func shaderDescription() throws -> XnaLaraShaderDescription {
        let description = mesh.model?.parameters.xnaLaraShaderDescriptions.first {
            if $0.baseName != shaderBase {
                return false
            }
            return Set($0.moduleNames) == shaderModules
        }
        guard let description = description else {
            throw NSError(domain: "GLLMeshExporting", code: 1, userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("Could not export model.", comment:"no mesh group found for model to export"),
                NSLocalizedRecoverySuggestionErrorKey : String(format: NSLocalizedString("No XNALara Mesh Group number corresponds to the shader %@.", comment: "can't write meshes without tangents"), shaderBase)])
        }
        return description
    }
    
    private func genericName(shaderDescription: XnaLaraShaderDescription) -> String {
        var name = ""
        
        let possibleGroups = mesh.usesAlphaBlending ? shaderDescription.alphaMeshGroups : shaderDescription.solidMeshGroups
        let nameRegex = /^MeshGroup([0-9]+)$/
        for groupName in possibleGroups {
            if let match = try? nameRegex.firstMatch(in: groupName) {
                name = match.1 + "_"
            }
        }
        assert(!name.isEmpty)
        
        // 2 - add display name, removing all underscores and newlines
        let illegalCharacters = /[\n\r ]/
        name += displayName.replacing(illegalCharacters, with: { _ in "-" })
        
        // 3 - write required parameters
        for parameterNames in shaderDescription.parameterUniformsInOrder {
            let param = renderParameter(name: parameterNames[0]) as! GLLFloatRenderParameter
            name += "_\(param.value)"
        }
        
        return name
    }
    
    private func textureUrls(description: XnaLaraShaderDescription) -> [URL] {
        return description.textureUniformsInOrder.map { texture(identifier: $0)!.textureURL! as URL }
    }
    
    func writeASCII() throws -> String {
        let shaderDescription = try shaderDescription()
        return mesh.writeAscii(withName: genericName(shaderDescription: shaderDescription), texture: textureUrls(description: shaderDescription))
    }
    
    func writeBinary() throws -> Data {
        let shaderDescription = try shaderDescription()
        return mesh.writeBinary(withName: genericName(shaderDescription: shaderDescription), texture: textureUrls(description: shaderDescription))
    }
    
    var shouldExport: Bool {
        let shaderDescription = try? shaderDescription()
        return isVisible && shaderDescription != nil
    }
}
