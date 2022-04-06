//
//  GLLModelMeshObj.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLModelMeshObj: GLLModelMesh {
    @objc init(asPartOfModel model: GLLModel, fileVertexAccessors: GLLVertexAttribAccessorSet, countOfVertices: Int, elementData: Data, textures: [String: GLLTextureAssignment], renderParameterValues: [String: AnyObject]) throws {
        super.init(asPartOfModel: model)
        countOfUVLayers = 1
        
        let tangents = calculateTangents(for: fileVertexAccessors)
        vertexDataAccessors = fileVertexAccessors.combining(with: tangents)
        
        self.countOfVertices = countOfVertices
        
        self.elementData = elementData
        self.countOfElements = elementData.count / 4
        
        // Previous actions may have disturbed vertex format (because it also depends on count of vertices) so uncache it.
        vertexFormat = vertexDataAccessors!.vertexFormat(withVertexCount: UInt(countOfVertices), hasIndices: true)
        
        // Setup material
        // Three options: Diffuse, DiffuseSpecular, DiffuseNormal, DiffuseSpecularNormal
        self.textures = textures
        self.renderParameterValues = renderParameterValues
        
        let objModelParams = try GLLModelParams.parameters(forName: "objFileParameters")
        shader = objModelParams.shader(base: "ObjDefault", modules: [], presentTextures: Array(textures.keys), vertexAccessors: vertexDataAccessors!, alphaBlending: true)
        
        // Always use blending, since I can't prove that it doesn't otherwise.
        usesAlphaBlending = true
    }
    
    override var hasBoneWeights: Bool {
        return false // OBJ files don't use them. They do use one bone matrix, for the model position, but that's it.
    }
    override var colorsAreFloats: Bool {
        // OBJ files that have colors store them as floats, and since they make use of features (e.g. values outside [0;1]) it's better to keep them that way.
        return true
    }
}
