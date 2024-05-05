//
//  GLLDataReader.swift
//  GLLara
//
//  Created by Torsten Kammer on 19.02.23.
//  Copyright © 2023 Torsten Kammer. All rights reserved.
//

protocol GLLDataReader {
    func readUint32() -> UInt32
    func readUint16() -> UInt16
    func readUint8() -> UInt8
    func readFloat32() -> Float32
    
    func readPascalString() -> String
    var isValid: Bool { get }
}
