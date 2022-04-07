//
//  GLLVertexArray.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import OpenGL.GL3
import OpenGL

@objc class GLLVertexArray: NSObject {
    
    private var vertexData: Data? = Data()
    private var elementData: Data? = Data()
    @objc var format: GLLVertexFormat
    private var optimizedFormat: GLLVertexAttribAccessorSet
    
    @objc init(format: GLLVertexFormat) {
        self.format = format
        
        let optimizedAttributes = format.attributes.compactMap { GLLVertexArray.optimizedVersion(attribute: $0) }
        let stride = optimizedAttributes.map { $0.sizeInBytes }.reduce(0) { $0 + $1 }
        
        var writingAccessors: [GLLVertexAttribAccessor] = []
        var offset = 0
        for attribute in optimizedAttributes {
            let accessor = GLLVertexAttribAccessor(attribute: attribute, dataBuffer: nil, offset: offset, stride: stride)
            offset += attribute.sizeInBytes
            writingAccessors.append(accessor)
        }
        
        self.optimizedFormat = GLLVertexAttribAccessorSet(accessors: writingAccessors)
        
        super.init()
    }
    
    var stride: Int {
        return optimizedFormat.accessors.first?.stride ?? 0
    }
    
    @objc var countOfVertices: Int {
        return vertexData!.count / stride
    }
    
    @objc var elementDataLength: Int {
        return elementData!.count
    }
    
    @objc func add(vertices: GLLVertexAttribAccessorSet, count: Int, elements: Data, elementsType: GLLVertexAttribComponentType) {
        // Process vertex data
        let actualStride = stride
        let newBytes = UnsafeMutableRawBufferPointer.allocate(byteCount: count * actualStride, alignment: MemoryLayout<Int32>.alignment)
        
        for i in 0..<count {
            for writeAccessor in optimizedFormat.accessors {
                let attribute = writeAccessor.attribute
                let readAccessor = vertices.accessor(semantic: attribute.semantic, layer: attribute.layer)!
                
                let originalVertex = readAccessor.element(at: i)
                let vertex = newBytes.baseAddress!.advanced(by: writeAccessor.offset(forElement: i))
                // Need to do some processing
                if attribute.semantic == .normal && attribute.size == .vec4 && attribute.type == .int2_10_10_10_Rev {
                    // Normal. Compress from float[3] to int_2_10_10_10_rev format
                    let normal = originalVertex.bindMemory(to: Float32.self, capacity: 3)
                    var value = UInt32(0)
                    value += packSignedFloat(value: normal[0], bits: 10);
                    value += packSignedFloat(value: normal[1], bits: 10) << 10;
                    value += packSignedFloat(value: normal[2], bits: 10) << 20;
                    vertex.bindMemory(to: UInt32.self, capacity: 1)[0] = value
                } else if attribute.semantic == .texCoord0 && attribute.size == .vec2 && attribute.type == .halfFloat {
                    // Tex coord. Compress to half float
                    let originalTexCoord = originalVertex.bindMemory(to: Float32.self, capacity: 2)
                    var newTexCoord = vertex.bindMemory(to: UInt16.self, capacity: 2)
                    newTexCoord[0] = halfFloat(value: originalTexCoord[0])
                    newTexCoord[1] = halfFloat(value: originalTexCoord[1])
                } else if attribute.semantic == .tangent0 && attribute.size == .vec4 && attribute.type == .int2_10_10_10_Rev {
                    let tangents = originalVertex.bindMemory(to: Float32.self, capacity: 4)
                    var normalized = UInt32(0)
                    let invLength = 1.0 / sqrt(tangents[0]*tangents[0] + tangents[1]*tangents[1] + tangents[2]*tangents[2]);
                    normalized |= packSignedFloat(value: tangents[0] * invLength, bits: 10);
                    normalized |= packSignedFloat(value: tangents[1] * invLength, bits: 10) << 10;
                    normalized |= packSignedFloat(value: tangents[2] * invLength, bits: 10) << 20;
                    normalized |= packSignedFloat(value: copysign(tangents[3], 1.0), bits: 2) << 30;
                    vertex.bindMemory(to: UInt32.self, capacity: 1)[0] = normalized
                } else if attribute.semantic == .boneWeights && attribute.size == .vec4 && attribute.type == .unsignedShort {
                    // Compress bone weights to half float
                    let weights = originalVertex.bindMemory(to: Float32.self, capacity: 4)
                    var newBoneWeights = vertex.bindMemory(to: UInt16.self, capacity: 4)
                    let sum = weights[0] + weights[0] + weights[1] + weights[2] + weights[3]
                    if sum == 0 {
                        newBoneWeights[0] = 0xFFFF
                        newBoneWeights[1] = 0
                        newBoneWeights[2] = 0
                        newBoneWeights[3] = 0
                    } else {
                        for j in 0..<4 {
                            newBoneWeights[j] = UInt16(packSignedFloat(value: weights[i] / sum, bits: 16))
                        }
                    }
                } else {
                    // Not optimized, just memcpy
                    vertex.copyMemory(from: vertex, byteCount: attribute.sizeInBytes)
                }
            }
        }
        
        vertexData!.append(newBytes.baseAddress!.bindMemory(to: UInt8.self, capacity: newBytes.count), count: newBytes.count)
        newBytes.deallocate()
        
        // Compress elements
        if self.format.hasIndices {
            var inputElementBytes = 0
            if elementsType == .unsignedInt || elementsType == .int {
                inputElementBytes = 4
            } else if elementsType == .unsignedShort || elementsType == .short {
                inputElementBytes = 2
            } else if elementsType == .unsignedByte || elementsType == .byte {
                inputElementBytes = 1
            } else {
                assertionFailure()
            }
            
            if inputElementBytes == format.numElementBytes {
                // Straight copy
                elementData!.append(elements)
            } else {
                let outputElementBytes = format.numElementBytes
                let count = elements.count / inputElementBytes
                elementData!.reserveCapacity(elementData!.count + count*outputElementBytes)
                if outputElementBytes < inputElementBytes {
                    // Downsample. Assumes little endian. RIP PPC :(
                    for i in 0..<count {
                        elementData!.append(elements.subdata(in: i*inputElementBytes ..< i*inputElementBytes+outputElementBytes))
                    }
                } else {
                    // Upsample. Assumes little endian. RIP PPC :(
                    for i in 0..<count {
                        elementData!.append(elements.subdata(in: i*inputElementBytes ..< (i+1)*inputElementBytes))
                        elementData!.append(contentsOf: Array.init(repeating: UInt8(0), count: outputElementBytes - inputElementBytes))
                    }
                }
            }
        }
    }
    
    // Returns nil if the optimal choice is to throw the data out entirely (in the case of padding)
    private static func optimizedVersion(attribute: GLLVertexAttrib) -> GLLVertexAttrib? {
        if attribute.semantic == .padding {
            return nil
        }
        
        /*// Change Normal (if float[3]) to vec4 with 2_10_10_10_rev encoding
        // (this adds a W component which gets ignored by the shader)
        if attribute.semantic == .normal && attribute.size == .vec3 && attribute.type == .float {
            return GLLVertexAttrib(semantic: .normal, layer: 0, size: .vec4, componentType: .int2_10_10_10_Rev)
        }
        // Change tex coord (if float[2]) to half[2]
        if attribute.semantic == .texCoord0 && attribute.size == .vec2 && attribute.type == .float {
            return GLLVertexAttrib(semantic: attribute.semantic, layer: attribute.layer, size: .vec2, componentType: .halfFloat)
        }
        // Change tangent (if float[4]) to vec4 with 2_10_10_10_rev encoding
        if attribute.semantic == .tangent0 && attribute.size == .vec4 && attribute.type == .float {
            return GLLVertexAttrib(semantic: attribute.semantic, layer: attribute.layer, size: .vec4, componentType: .int2_10_10_10_Rev)
        }
        // Change bone weight (if float[4]) to ushort[4]
        if attribute.semantic == .boneWeights && attribute.size == .vec4 && attribute.type == .float {
            return GLLVertexAttrib(semantic: attribute.semantic, layer: attribute.layer, size: .vec4, componentType: .unsignedShort)
        }*/
        
        // Default: No change
        return attribute
    }
    
    private func packSignedFloat(value: Float32, bits: Int) -> UInt32 {
        /*
         f(1.0) = max
         f(-1.0) = min
         1.0 * m + a = max
         -1.0 * m + a = min
         2a = max + min
         a = 0.5*(max+min)
         1.0 * m + 0.5*(max+min) = max
         m = max - 0.5*(max+min)

         */
        if value.isNaN || value.isInfinite {
            return 0
        }

        let max = (1 << (bits-1)) - 1
        let min = -(1 << (bits-1))
        let offset = Float32(0.5) * Float32(max+min)
        let factor = Float32(max) - offset
        let scaled = value * factor + offset
        let signedValue = Int32(scaled)
        let mask = (1 << bits) - 1
        return UInt32(bitPattern: signedValue) & UInt32(mask)
    }

    private func reduceFloat(value: Float32, exponentBits: Int, mantissaBits: Int, signBits: Int = 1) -> UInt32 {
        let valueBits = value.bitPattern

        var mantissa = valueBits & ((1 << 23) - 1)
        let exponent = Int32((valueBits >> 23) & 0xFF) - 127
        let sign = (valueBits >> 31) & 0x1
 
        let bias = Int32((1 << (exponentBits - 1)) - 1)
        var newExponent = exponent + bias
        let maxBiasedExponent = Int32((1 << exponentBits) - 1)
        if newExponent <= 0 {
            // Set to 0. Don't muck around with denormals
            newExponent = 0;
            mantissa = 0;
        } else if newExponent >= maxBiasedExponent {
            // Set to inf.
            newExponent = maxBiasedExponent;
            mantissa = 0;
        }

        var result = UInt32(0);
        // Mantissa
        result |= mantissa >> (23 - mantissaBits);

        // Exponent
        result |= UInt32(newExponent << mantissaBits);

        if (signBits > 0) {
            result |= sign << (exponentBits + mantissaBits);
        }
        return result;
    }

    private func halfFloat(value: Float32) -> UInt16{
        return UInt16(reduceFloat(value: value, exponentBits: 5, mantissaBits: 10, signBits: 1));
    }
    
    @objc var vertexArrayIndex = UInt32(0)
    
    @objc func upload() {
        // Create the element and vertex buffers, and spend a lot of time setting up the vertex attribute arrays and pointers.
        glGenVertexArrays(1, &vertexArrayIndex);
        glBindVertexArray(vertexArrayIndex);
        
        let usedBuffers: GLsizei = self.format.hasIndices ? 2 : 1;
        var buffers: [GLuint] = [ 0, 0 ];
        buffers.withUnsafeMutableBufferPointer {
            glGenBuffers(usedBuffers, $0.baseAddress);
        }
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffers[0]);
        _ = vertexData!.withUnsafeBytes {
            glBufferData(GLenum(GL_ARRAY_BUFFER), vertexData!.count, $0, GLenum(GL_STATIC_DRAW));
        }
            
        for attributeAccessor in optimizedFormat.accessors {
            let attribute = attributeAccessor.attribute;
            var attribIndex = GLuint(attribute.semantic.rawValue);
            if (attribute.semantic == .tangent0 || attribute.semantic == .texCoord0) {
                attribIndex += 2 * GLuint(attribute.layer);
            }
            
            glEnableVertexAttribArray(attribIndex);
            
            if (attribute.semantic == .boneIndices) {
                glVertexAttribIPointer(attribIndex, GLint(attribute.numberOfElements), GLenum(attribute.type.rawValue), GLsizei(attributeAccessor.stride), UnsafeRawPointer(bitPattern: attributeAccessor.dataOffset));
            } else {
                var normalized = GLboolean(GL_FALSE);
                if (attribute.type.rawValue == GL_UNSIGNED_BYTE && attribute.semantic == .color) {
                    normalized = GLboolean(GL_TRUE);
                } else if (attribute.type.rawValue == GL_INT_2_10_10_10_REV) {
                    normalized = GLboolean(GL_TRUE);
                } else if (attribute.type.rawValue == GL_UNSIGNED_SHORT && attribute.semantic == .boneWeights) {
                    normalized = GLboolean(GL_TRUE);
                }
                glVertexAttribPointer(attribIndex, GLint(attribute.numberOfElements), GLenum(attribute.type.rawValue), normalized, GLsizei(attributeAccessor.stride), UnsafeRawPointer(bitPattern: attributeAccessor.dataOffset));
            }
        }
        
        if (self.format.hasIndices) {
            glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), buffers[1]);
            _ = elementData!.withUnsafeBytes {
                glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), elementData!.count, $0, GLenum(GL_STATIC_DRAW));
            }
        }
        
        glBindVertexArray(0);
        glDeleteBuffers(usedBuffers, buffers);
        
        vertexData = nil;
        elementData = nil;
    }
    
    func unload() {
        glDeleteVertexArrays(1, [ vertexArrayIndex ]);
        vertexArrayIndex = 0;
    }
}
