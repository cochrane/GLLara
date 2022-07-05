//
//  GLLVertexFormat.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

struct GLLVertexFormat: Hashable {
    
    init(attributes: [GLLVertexAttrib], countOfVertices: Int, hasIndices: Bool) {
        self.attributes = attributes
        self.hasIndices = hasIndices
        
        if hasIndices && countOfVertices < Int(UInt16.max) {
            indexType = .uint16
        } else {
            indexType = .uint32
        }
        
    }
    
    let attributes: [GLLVertexAttrib]
    let indexType: MTLIndexType
    let hasIndices: Bool
    
    var stride: Int {
        return attributes.reduce(0) { $0 + $1.sizeInBytes }
    }
}
