//
//  GLLVertexAttribAccessorSet.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLVertexAttribAccessorSet: NSObject {
    @objc var accessors: [GLLVertexAttribAccessor]
    
    @objc init(accessors: [GLLVertexAttribAccessor]) {
        self.accessors = accessors
    }
    
    func combining(with other: GLLVertexAttribAccessorSet) -> GLLVertexAttribAccessorSet {
        return GLLVertexAttribAccessorSet(accessors: accessors + other.accessors)
    }
    
    @objc func accessor(semantic: GLLVertexAttribSemantic, layer: Int = 0) -> GLLVertexAttribAccessor? {
        return accessors.first {
            $0.attribute.semantic == semantic && $0.attribute.layer == layer
        }
    }
    
    func vertexFormat(vertexCount: Int, hasIndices: Bool) -> GLLVertexFormat {
        return GLLVertexFormat(attributes: accessors.map { $0.attribute }, countOfVertices: UInt(vertexCount), hasIndices: hasIndices)
    }
}
