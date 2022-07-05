//
//  GLLVertexAttrib.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

struct GLLVertexAttrib: Hashable, Comparable {
    init(semantic: GLLVertexAttribSemantic, layer: Int, format: MTLVertexFormat) {
        self.semantic = semantic
        self.layer = layer
        self.format = format
    }
    
    let semantic: GLLVertexAttribSemantic
    let layer: Int
    let format: MTLVertexFormat
    
    var sizeInBytes: Int {
        switch format {
        case .invalid:
            return 0
            
        case .uchar2:
            return 2
        case .uchar3:
            return 3
        case .uchar4:
            return 4
        case .char2:
            return 2
        case .char3:
            return 3
        case .char4:
            return 4
        case .uchar2Normalized:
            return 2
        case .uchar3Normalized:
            return 3
        case .uchar4Normalized:
            return 4
        case .char2Normalized:
            return 2
        case .char3Normalized:
            return 3
        case .char4Normalized:
            return 4
        case .ushort2:
            return 2*2
        case .ushort3:
            return 2*3
        case .ushort4:
            return 2*4
        case .short2:
            return 2*2
        case .short3:
            return 2*3
        case .short4:
            return 2*4
        case .ushort2Normalized:
            return 2*2
        case .ushort3Normalized:
            return 2*3
        case .ushort4Normalized:
            return 2*4
        case .short2Normalized:
            return 2*2
        case .short3Normalized:
            return 2*3
        case .short4Normalized:
            return 2*4
        case .half2:
            return 2*2
        case .half3:
            return 2*3
        case .half4:
            return 2*4
        case .float:
            return 4
        case .float2:
            return 2*4
        case .float3:
            return 3*4
        case .float4:
            return 4*4
        case .int:
            return 4
        case .int2:
            return 2*4
        case .int3:
            return 3*4
        case .int4:
            return 4*4
        case .uint:
            return 4
        case .uint2:
            return 2*4
        case .uint3:
            return 3*4
        case .uint4:
            return 4*4
        case .int1010102Normalized:
            return 4
        case .uint1010102Normalized:
            return 4
        case .uchar4Normalized_bgra:
            return 4
        case .uchar:
            return 1
        case .char:
            return 1
        case .ucharNormalized:
            return 1
        case .charNormalized:
            return 1
        case .ushort:
            return 2
        case .short:
            return 2
        case .ushortNormalized:
            return 2
        case .shortNormalized:
            return 2
        case .half:
            return 2
        @unknown default:
            return 0
        }
    }
    
    var identifier: Int {
        // TODO Needs to match XnaLaraShader attributes
        switch self.semantic {
        case .position:
            return 0;
        case .normal:
            return 1;
        case .color:
            return 2;
        case .texCoord0:
            if (self.layer == 0) {
                return 3;
            } else {
                return 4;
            }
        case .tangent0:
            return 5;
        case .boneIndices:
            return 6;
        case .boneWeights:
            return 7;
                
        default:
            return 100;
        }
        /*if (self.semantic == GLLVertexAttribTangent0 || self.semantic == GLLVertexAttribTexCoord0) {
            return self.semantic + 2 * self.layer;
        } else {
            return self.semantic;
        }*/
    }
    
    static func < (lhs: GLLVertexAttrib, rhs: GLLVertexAttrib) -> Bool {
        if lhs.semantic.rawValue < rhs.semantic.rawValue {
            return true
        } else if rhs.semantic.rawValue < lhs.semantic.rawValue {
            return false
        }
        
        return lhs.layer < rhs.layer
    }
}
