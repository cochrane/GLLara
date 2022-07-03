//
//  GLLVertexAttribAccessorSet.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

@objc class GLLVertexAttribAccessorSet: NSObject {
    @objc var accessors: [GLLVertexAttribAccessor]
    
    @objc let vertexDescriptor: MTLVertexDescriptor
    
    @objc init(accessors: [GLLVertexAttribAccessor]) {
        self.accessors = accessors
        
        // Set up the vertex descriptor
        // - Keep track of which buffers are found in the layouts section
        var orderedBuffers: [Data] = []
        vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.layouts[10].stepFunction = .perVertex
        vertexDescriptor.layouts[10].stride = accessors.first?.stride ?? 0
        for accessor in accessors {
            let index = accessor.attribute.identifier
            vertexDescriptor.attributes[index].offset = accessor.dataOffset
            vertexDescriptor.attributes[index].format = accessor.attribute.mtlFormat
            vertexDescriptor.attributes[index].bufferIndex = 10
            
            if let data = accessor.dataBuffer {
                if let bufferIndex = orderedBuffers.firstIndex(of: data) {
                    vertexDescriptor.attributes[index].bufferIndex = bufferIndex
                } else {
                    let bufferIndex = orderedBuffers.count + 10
                    vertexDescriptor.attributes[index].bufferIndex = bufferIndex
                    orderedBuffers.append(data)
                    vertexDescriptor.layouts[bufferIndex].stepFunction = .perVertex
                    vertexDescriptor.layouts[bufferIndex].stride = accessor.stride
                }
            }
        }
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
        return GLLVertexFormat(attributes: accessors.map { $0.attribute }, countOfVertices: vertexCount, hasIndices: hasIndices)
    }
}

extension GLLVertexAttribAccessor {
    func typedElement<T>(at: Int, type: T.Type) -> UnsafePointer<T> {
        // TODO do a runtime check here
        return element(at: at).bindMemory(to: T.self, capacity: Int(attribute.numberOfElements))
    }
}
