//
//  TRDataStream.m
//  TR Poser
//
//  Created by Torsten Kammer on 13.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//
import Foundation
import zlib

class TRInDataStream: GLLDataReader {
    var levelData: Data
    var position: Int = 0
    
    init(data: Data) {
        levelData = data
    }
    
    func readUint32() -> UInt32 {
        return readInts(count: 1, type: UInt32.self)[0]
    }
    
    func readUint16() -> UInt16 {
        return readInts(count: 1, type: UInt16.self)[0]
    }
    
    func readUint8() -> UInt8 {
        return readInts(count: 1, type: UInt8.self)[0]
    }
    
    func readFloat32() -> Float32 {
        return readFloats(count: 1, type: Float32.self)[0]
    }
    
    func readInt32() -> Int32 {
        return readInts(count: 1, type: Int32.self)[0]
    }
    
    func readInt16() -> Int16 {
        return readInts(count: 1, type: Int16.self)[0]
    }
    
    func readInt8() -> Int8 {
        return readInts(count: 1, type: Int8.self)[0]
    }
    
    func readInts<T: BinaryInteger>(count: Int, type: T.Type) -> [T] {
        // This only works if input data has same endianness as CPU
        // Luckily (sadly, but lucky in this case), all big endian CPUs have died out ages ago.
        var result = Array<T>(repeating: 0, count: count)
        readItems(count: count, into: &result)
        return result
    }
    
    func readFloats<T: BinaryFloatingPoint>(count: Int, type: T.Type) -> [T] {
        // This only works if input data has same endianness as CPU
        // Luckily (sadly, but lucky in this case), all big endian CPUs have died out ages ago.
        var result = Array<T>(repeating: 0, count: count)
        readItems(count: count, into: &result)
        return result
    }
    
    func readItems<T>(count: Int, into result: inout [T]) {
        if isAtEnd {
            return
        }
        let rangeEnd = min(levelData.count, position + count * MemoryLayout<T>.stride)
        _ = result.withUnsafeMutableBytes { output in
            levelData.copyBytes(to: output, from: position ..< rangeEnd)
        }
        position = rangeEnd
    }
    
    func skip(bytes: Int) {
        position += bytes
    }
    
    func skipField16(elementWidth: Int) {
        let count = readUint16()
        skip(bytes: Int(count) * elementWidth)
    }
    
    func skipField32(elementWidth: Int) {
        let count = readUint16()
        skip(bytes: Int(count) * elementWidth)
    }
    
    func data(length: Int) -> Data? {
        if isAtEnd || position + length > levelData.count {
            return nil
        }
        let data = levelData.subdata(in: position ..< position + length)
        position += length
        return data
    }
    
    func substream(length: Int) -> TRInDataStream? {
        guard let data = data(length: length) else {
            return nil
        }
        return TRInDataStream(data: data)
    }
    
    var isAtEnd: Bool {
        return position >= levelData.count
    }
    
    var isValid: Bool {
        return position <= levelData.count
    }
    
    func readPascalString() -> String {
        var length = 0
        var lengthByte = 0
        var bytesRead = 0
        repeat {
            lengthByte = Int(readUint8())
            length += (lengthByte & 0x7F) << (7*bytesRead)
            bytesRead += 1
        } while isValid && (lengthByte & 0x80 != 0)
        if !isValid || length == 0 {
            return ""
        }
        
        let result = readInts(count: length, type: UInt8.self)
        return String(bytes: result, encoding: .utf8) ?? ""
    }
    
    func decompressStream(compressedLength: Int, uncompressedLength: Int) throws -> TRInDataStream? {
        if position + compressedLength > levelData.count {
            position += compressedLength
            return nil
        }
        
        var uncompressedData = Data(count: uncompressedLength)
        var actualUncompressedLength: uLongf = uLongf(uncompressedLength)
    
        let uncompressResult = levelData.withUnsafeBytes { (levelDataBytes: UnsafeRawBufferPointer) in
            uncompressedData.withUnsafeMutableBytes { (uncompressedBytes: UnsafeMutableRawBufferPointer) in
                uncompress(uncompressedBytes.bindMemory(to: UInt8.self).baseAddress, &actualUncompressedLength, levelDataBytes.bindMemory(to: UInt8.self).baseAddress!.advanced(by: position), uLong(compressedLength))
            }
        }
        if uncompressResult != Z_OK {
            throw NSError(domain: "TRInDataStream", code: Int(uncompressResult), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("Could not decompress part of the data.", comment: "uncompress failed"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The compressed parts of the file could not be processed. The file may be damaged.", comment: "uncompress failed")
            ])
        }
        if actualUncompressedLength < uncompressedLength {
            throw NSError(domain: "TRInDataStream", code: Int(uncompressResult), userInfo: [
                NSLocalizedDescriptionKey : NSLocalizedString("Could not decompress part of the data.", comment: "uncompress failed"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("A piece of compressed data was shorter than it should have been. The file may be damaged.", comment: "uncompress failed")
            ])
        }
        
        position += compressedLength
        return TRInDataStream(data: uncompressedData)
    }
}
