//
//  GLLModelBone.swift
//  GLLara
//
//  Created by Torsten Kammer on 19.02.23.
//  Copyright © 2023 Torsten Kammer. All rights reserved.
//

import Foundation

/*!
 * @abstract Description of a bone in a model.
 * @discussion A bone is a transformable entity; vertices belong to one or several bones, with different weights. The bone here is purely a static description and with default values. It does not contain any transformation information.
 */
@objc class GLLModelBone: NSObject {
    @objc let name: String
    @objc let parentIndex: Int
    @objc var position: simd_float3
    
    // Transformations for the bone
    @objc let inversePositionMatrix: matrix_float4x4
    @objc let positionMatrix: matrix_float4x4
    
    @objc var parent: GLLModelBone? = nil
    @objc var children: [GLLModelBone] = []
    
    override init() {
        name = NSLocalizedString("Root bone", comment: "Only bone in a boneless format")
        position = SIMD3(repeating: 0.0)
        parentIndex = -1
        positionMatrix = matrix_identity_float4x4
        inversePositionMatrix = matrix_identity_float4x4
        
        super.init()
    }
    
    init(sequentialData stream: GLLDataReader) throws {
        guard stream.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file breaks off in the middle of the bones section. Maybe it is damaged?", comment: "Premature end of file error.")
            ])
        }
        
        name = stream.readPascalString()
        let parentIndexValue = stream.readInt16()
        parentIndex = (parentIndexValue == Int16.max) ? -1 : Int(parentIndexValue)
        let x = stream.readFloat32()
        let y = stream.readFloat32()
        let z = stream.readFloat32()
        position = SIMD3(x, y, z)
        
        positionMatrix = simd_mat_positional(SIMD4(position, 1.0))
        inversePositionMatrix = simd_mat_positional(SIMD4(-position, 1.0))
        
        guard stream.isValid else {
            throw NSError(domain: GLLModelLoadingErrorDomain, code: Int(GLLModelLoadingErrorCode.prematureEndOfFile.rawValue), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("The file is missing some data.", comment: "Premature end of file error"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file breaks off in the middle of the bones section. Maybe it is damaged?", comment: "Premature end of file error.")
            ])
        }
    }
    
    // Export
    func writeASCII() -> String {
        var result = ""
        
        result.append("\(name)\n")
        result.append("\(parentIndex)\n")
        result.append("\(position.x) \(position.y) \(position.z)\n")
        
        return result
    }
    
    func writeBinary() -> Data {
        let stream = TROutDataStream()
        
        stream.appendPascalString(name)
        stream.appendUint16(UInt16(truncating: parentIndex as NSNumber))
        stream.appendFloat32(position.x)
        stream.appendFloat32(position.y)
        stream.appendFloat32(position.z)
        
        return stream.data()
    }
}
