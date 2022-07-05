//
//  GLLVertexArray.swift
//  GLLara
//
//  Created by Torsten Kammer on 06.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import Metal

@objc class GLLVertexArray: NSObject {
    
    private var vertexData: Data? = Data()
    private var elementData: Data? = Data()
    var format: GLLVertexFormat
    @objc var optimizedFormat: GLLVertexAttribAccessorSet
    
    var vertexBuffer: MTLBuffer? = nil
    var elementBuffer: MTLBuffer? = nil
    
    @objc var debugLabel: String = "gllvertexarray"
    
    init(format: GLLVertexFormat) {
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
    
    var vertexDescriptor: MTLVertexDescriptor {
        return optimizedFormat.vertexDescriptor
    }
    
    var stride: Int {
        return optimizedFormat.accessors.first?.stride ?? 0
    }
    
    var numberOfElementBytes: Int {
        if !format.hasIndices {
            return 0
        }
        switch format.indexType {
        case .uint16:
            return 2
        case .uint32:
            return 4
        @unknown default:
            fatalError()
        }
    }
    
    @objc var countOfVertices: Int {
        return vertexData!.count / stride
    }
    
    @objc var elementDataLength: Int {
        return elementData!.count
    }
    
    @objc func add(vertices: GLLVertexAttribAccessorSet, count: Int, elements: Data?, bytesPerElement: Int) {
        // Process vertex data
        let actualStride = stride
        let newBytes = UnsafeMutableRawBufferPointer.allocate(byteCount: count * actualStride, alignment: MemoryLayout<Int32>.alignment)
        
        for i in 0..<count {
            for writeAccessor in optimizedFormat.accessors {
                let attribute = writeAccessor.attribute
                let readAccessor = vertices.accessor(semantic: attribute.semantic, layer: attribute.layer)!
                
                readAccessor.withBytes(element: i) { originalVertex in
                    let vertex = newBytes.baseAddress!.advanced(by: writeAccessor.offset(element: i))
                    // Need to do some processing
                    if attribute.semantic == .normal && attribute.mtlFormat == .int1010102Normalized {
                        // Normal. Compress from float[3] to int_2_10_10_10_rev format
                        let normal = originalVertex.bindMemory(to: Float32.self)
                        var value = UInt32(0)
                        value += packSignedFloat(value: normal[0], bits: 10);
                        value += packSignedFloat(value: normal[1], bits: 10) << 10;
                        value += packSignedFloat(value: normal[2], bits: 10) << 20;
                        vertex.bindMemory(to: UInt32.self, capacity: 1)[0] = value
                    } else if attribute.semantic == .texCoord0 && attribute.mtlFormat == .half2 {
                        // Tex coord. Compress to half float
                        let originalTexCoord = originalVertex.bindMemory(to: Float32.self)
                        let newTexCoord = vertex.bindMemory(to: UInt16.self, capacity: 2)
                        newTexCoord[0] = halfFloat(value: originalTexCoord[0])
                        newTexCoord[1] = halfFloat(value: originalTexCoord[1])
                    } else if attribute.semantic == .tangent0 && attribute.mtlFormat == .int1010102Normalized {
                        let tangents = originalVertex.bindMemory(to: Float32.self)
                        var normalized = UInt32(0)
                        let invLength = 1.0 / sqrt(tangents[0]*tangents[0] + tangents[1]*tangents[1] + tangents[2]*tangents[2]);
                        normalized |= packSignedFloat(value: tangents[0] * invLength, bits: 10);
                        normalized |= packSignedFloat(value: tangents[1] * invLength, bits: 10) << 10;
                        normalized |= packSignedFloat(value: tangents[2] * invLength, bits: 10) << 20;
                        normalized |= packSignedFloat(value: copysign(tangents[3], 1.0), bits: 2) << 30;
                        vertex.bindMemory(to: UInt32.self, capacity: 1)[0] = normalized
                    } else if attribute.semantic == .boneWeights && attribute.mtlFormat == .uchar2Normalized {
                        // Compress bone weights to half float
                        let weights = originalVertex.bindMemory(to: Float32.self)
                        let newBoneWeights = vertex.bindMemory(to: UInt16.self, capacity: 4)
                        let sum = weights[0] + weights[0] + weights[1] + weights[2] + weights[3]
                        if sum == 0 {
                            newBoneWeights[0] = 0xFFFF
                            newBoneWeights[1] = 0
                            newBoneWeights[2] = 0
                            newBoneWeights[3] = 0
                        } else {
                            for j in 0..<4 {
                                newBoneWeights[j] = UInt16(packSignedFloat(value: weights[j] / sum, bits: 16))
                            }
                        }
                    } else if attribute.semantic == .boneWeights && attribute.mtlFormat == .float4 {
                        // Compress bone weights to half float
                        let weights = originalVertex.bindMemory(to: Float32.self)
                        let newBoneWeights = vertex.bindMemory(to: Float32.self, capacity: 4)
                        let sum = weights[0] + weights[1] + weights[2] + weights[3]
                        if sum == 0 {
                            newBoneWeights[0] = 1.0
                            newBoneWeights[1] = 0
                            newBoneWeights[2] = 0
                            newBoneWeights[3] = 0
                        } else {
                            for j in 0..<4 {
                                newBoneWeights[j] = weights[j] / sum
                            }
                        }
                    } else {
                        // Not optimized, just memcpy
                        vertex.copyMemory(from: originalVertex.baseAddress!, byteCount: attribute.sizeInBytes)
                    }
                }
            }
        }
        
        vertexData!.append(newBytes.baseAddress!.bindMemory(to: UInt8.self, capacity: newBytes.count), count: newBytes.count)
        newBytes.deallocate()
        
        // Compress elements
        if self.format.hasIndices, let elements = elements {
            let ourElementBytes = numberOfElementBytes
            if bytesPerElement == ourElementBytes {
                // Straight copy
                elementData!.append(elements)
            } else {
                let additionalCount = elements.count / bytesPerElement
                elementData!.reserveCapacity(elementData!.count + count*ourElementBytes)
                if ourElementBytes <= bytesPerElement {
                    // Downsample. Assumes little endian. RIP PPC :(
                    for i in 0..<additionalCount {
                        elementData!.append(elements.subdata(in: i*bytesPerElement ..< i*bytesPerElement+ourElementBytes))
                    }
                } else {
                    // Upsample. Assumes little endian. RIP PPC :(
                    for i in 0..<additionalCount {
                        elementData!.append(elements.subdata(in:i*bytesPerElement ..< (i+1)*bytesPerElement))
                        elementData!.append(contentsOf: Array.init(repeating: UInt8(0), count: ourElementBytes - bytesPerElement))
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
        // TODO do this in Metal style
        // Can we use vertex descriptors to simplify this? It seems like we're actually fairly close to them already.
        // Edit: Yes! We can do that! They're specifically for this in fact!
        
        let device = GLLResourceManager.shared().metalDevice!
        vertexData!.withUnsafeBytes {
            vertexBuffer = device.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeManaged)
            vertexBuffer?.label = "vertex-" + debugLabel
        }
        elementData!.withUnsafeBytes {
            elementBuffer = device.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeManaged)
            elementBuffer?.label = "elements-" + debugLabel
        }
        vertexData = nil
        elementData = nil
    }
}
