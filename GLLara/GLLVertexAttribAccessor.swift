//
//  GLLVertexAttribAccessor.swift
//  GLLara
//
//  Created by Torsten Kammer on 04.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLVertexAttribAccessor: NSObject {
    
    @objc convenience init(semantic: GLLVertexAttribSemantic, layer: Int = 0, format: MTLVertexFormat, dataBuffer: Data?, offset: Int, stride: Int) {
        let attribute = GLLVertexAttrib(semantic: semantic, layer: layer, format: format)
        
        self.init(attribute: attribute, dataBuffer: dataBuffer, offset: offset, stride: stride)
    }
    
    init(attribute: GLLVertexAttrib, dataBuffer: Data?, offset: Int, stride: Int) {
        self.attribute = attribute
        self.dataBuffer = dataBuffer
        self.dataOffset = offset
        self.stride = stride
    }
    
    let attribute: GLLVertexAttrib
    let dataBuffer: Data?
    let dataOffset: Int
    let stride: Int
    
    func offset(element: Int) -> Int {
        return dataOffset + element * stride
    }
    
    func range(element: Int) -> Range<Int> {
        let start = offset(element: element)
        let length = attribute.sizeInBytes
        return start ..< (start + length)
    }
    
    func elementData(at element: Int) -> Data? {
        guard let dataBuffer = dataBuffer else {
            return nil
        }
        return try! dataBuffer.checkedSubdata(in: range(element: element))
    }
    
    func typedElementArray<T>(at element: Int, type: T.Type) -> [T] {
        guard let dataBuffer = dataBuffer else {
            assertionFailure()
            return []
        }
        
        return dataBuffer.withUnsafeBytes { start -> [T] in
            let slice = start[range(element: element)]
            let typed = UnsafeRawBufferPointer(rebasing: slice).bindMemory(to: T.self)
            return Array(typed)
        }
    }
    
    func withBytes(element: Int, action: (UnsafeRawBufferPointer) throws ->()) rethrows {
        guard let dataBuffer = dataBuffer else {
            assertionFailure()
            return
        }
        
        try dataBuffer.withUnsafeBytes { start in
            let slice = start[range(element: element)]
            try action(UnsafeRawBufferPointer(rebasing: slice))
        }
    }
}
