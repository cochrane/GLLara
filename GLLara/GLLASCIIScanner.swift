//
//  GLLASCIIScanner.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//
import Foundation

/*!
 * @abstract Reader for the .mesh.ascii format.
 * @discussion It was deliberately designed to have the same interface as the
 * TRInDataStream. Thus, it can read integers in different widths, although
 * parsing them from an ASCII file is always the same work.
 */
class GLLASCIIScanner: GLLDataReader {
    init(string: String) {
        scanner = Scanner(string: string)
        // Use american english at all times, because that is the number format used.
        scanner.locale = Locale(identifier: "en_US")
    }
    
    private let scanner: Scanner
    
    func readUint32() -> UInt32 {
        return UInt32(readInteger())
    }
    
    func readUint16() -> UInt16 {
        return UInt16(readInteger())
    }
    
    func readInt16() -> Int16 {
        return Int16(readInteger())
    }
    
    func readUint8() -> UInt8 {
        return UInt8(readInteger())
    }
    
    func readFloat32() -> Float32 {
        skipComments()
        if scanner.isAtEnd {
            isValid = false
            return 0.0
        }
        
        guard let result = scanner.scanFloat() else {
            if (scanner.scanString("NaN") != nil) {
                // Haha, very funny. Idiots.
                return Float.nan
            } else {
                isValid = false
                return 0.0
            }
        }
        return result
    }
    
    func readPascalString() -> String {
        skipComments()
        if scanner.isAtEnd {
            isValid = false
            return ""
        }
        
        _ = scanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines)
        guard let result = scanner.scanUpToCharacters(from: CharacterSet.newlines) else {
            isValid = false
            return ""
        }
        return result
    }
    
    func hasNewline() -> Bool {
        // Skip only whitespace, not newline, because the scanner won't recognize the newline otherwise
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        if scanner.scanString("#") != nil {
            // Has a comment, which ends a line.
            _ = scanner.scanUpToCharacters(from: CharacterSet.newlines)
            scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
            return true
        } else if scanner.scanCharacters(from: CharacterSet.newlines) != nil {
            // Has newline, which obviously ends a line.
            scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
            return true
        }
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
        return false
    }
    
    var isValid: Bool = true
    
    private func skipComments() {
        while scanner.scanString("#") != nil {
            _ = scanner.scanUpToCharacters(from: CharacterSet.newlines)
        }
    }
    
    private func readInteger() -> Int {
        skipComments()
        if scanner.isAtEnd {
            isValid = false
            return 0
        }
        
        guard let result = scanner.scanInt() else {
            isValid = false
            return 0
        }
        return result
    }
}
