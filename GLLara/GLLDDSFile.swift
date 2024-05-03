//
//  GLLDDSFile.swift
//  GLLara
//
//  Created by Torsten Kammer on 28.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Foundation

// All information about the DDS file format is taken from
// http://msdn.microsoft.com/archive/default.asp?url=/archive/en-us/directx9_c/directx/graphics/reference/ddsfilereference/ddsfileformat.asp

@objc enum GLLDDSDataFormat: Int
{
    case dxt1
    case dxt3
    case dxt5
    case argb1555
    case argb4
    case rgb565
    case bgr8
    case bgra8
    case rgba8
    case bgrx8
}

/**
 * # Parses DDS files.
 *
 * Much of this is based on older code that was plain C and had
 * become too hard to maintain, and especially add error support to. This class
 * does not handle decompression and the like; it only provides the data to be
 * loaded into the GPU.
 */
@objc class GLLDDSFile: NSObject {
    struct DDSPixelFormat {
        var size: UInt32 = 0
        var flags: UInt32 = 0
        var fourCC: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)
        var rgbBitCount: UInt32 = 0
        var rBitMask: UInt32 = 0
        var gBitMask: UInt32 = 0
        var bBitMask: UInt32 = 0
        var aBitMask: UInt32 = 0
    }
    
    struct DDSCaps {
        var caps1: UInt32 = 0
        var caps2: UInt32 = 0
        var reserved1: UInt32 = 0
        var reserved2: UInt32 = 0
    }
    
    struct DDSFileHeader {
        var size: UInt32 = 0
        var flags: UInt32 = 0
        var height: UInt32 = 0
        var width: UInt32 = 0
        var pitchOrLinearSize: UInt32 = 0
        var depth: UInt32 = 0
        var mipMapCount: UInt32 = 0
        var reserved1: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        var pixelFormat = DDSPixelFormat()
        var caps = DDSCaps()
        var reserved2: UInt32 = 0
    }
    
    @objc let fileData: Data
    @objc let width: Int
    @objc let height: Int
    @objc let numMipmaps: Int
    @objc let dataFormat: GLLDDSDataFormat
    
    @objc var hasMipmaps: Bool {
        return numMipmaps > 0
    }
    @objc var isCompressed: Bool {
        return dataFormat == .dxt1 || dataFormat == .dxt3 || dataFormat == .dxt5
    }
    
    @objc convenience init(contentsOf: URL) throws {
        let data = try Data(contentsOf: contentsOf, options: [.mappedIfSafe])
        try self.init(data: data)
    }
    
    @objc init(data: Data) throws {
        self.fileData = data
        
        guard data.count >= 128 && data[0] == Character("D").asciiValue! && data[1] == Character("D").asciiValue! && data[2] == Character("S").asciiValue! && data[3] == Character(" ").asciiValue! else {
            throw NSError(domain:"ddsError", code:1, userInfo:[
                NSLocalizedDescriptionKey : NSLocalizedString("This DDS file is corrupt.", comment: "DDS: Does not start with DDS"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file cannot be opened because it has an incorrect start sequence. This usually indicates that the file is damaged or not a DDS file at all.", comment:"DDS: Does not start with DDS")]);
        }
        var header = DDSFileHeader()
        _ = withUnsafeMutableBytes(of: &header) {
            data.copyBytes(to: $0, from: 4 ..< MemoryLayout<DDSFileHeader>.size + 4)
        }
        if header.size != 124 {
            throw NSError(domain:"ddsError", code:2, userInfo:[
                NSLocalizedDescriptionKey : NSLocalizedString("This DDS file is not supported.", comment: "DDS: Header size wrong"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file cannot be read because it uses a different header size than normal. This may be because it uses a newer version of the file format, or because it is damaged.", comment: "DDS: Header size wrong")])
        }
        if header.pixelFormat.size != 32 {
            throw NSError(domain:"ddsError", code:3, userInfo:[
                NSLocalizedDescriptionKey : NSLocalizedString("This DDS file is not supported.", comment: "DDS: Pixel format size wrong"),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file cannot be read because it uses a different header size than normal. This may be because it uses a newer version of the file format, or because it is damaged.", comment: "DDS: Pixel format size wrong")])
        }
        
        if ((header.pixelFormat.flags & 4) != 0) {
            // Use the FourCC
            if header.pixelFormat.fourCC.0 == Character("D").asciiValue! && header.pixelFormat.fourCC.1 == Character("X").asciiValue! &&  header.pixelFormat.fourCC.2 == Character("T").asciiValue! {
                if header.pixelFormat.fourCC.3 == Character("1").asciiValue! {
                    dataFormat = .dxt1
                } else if header.pixelFormat.fourCC.3 == Character("3").asciiValue! {
                    dataFormat = .dxt3
                } else if header.pixelFormat.fourCC.3 == Character("5").asciiValue! {
                    dataFormat = .dxt5
                } else {
                    throw NSError(domain:"ddsError", code:1, userInfo:[
                        NSLocalizedDescriptionKey : NSLocalizedString("Graphics format is not supported.", comment:"DDS: Unknown FourCC"),
                        NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file cannot be read because it uses a compressed data format that is not supported. Only DXT1, DXT3 and DXT5 formats are supported.", comment: "DDS: Unknown FourCC")]);
                }
            } else {
                throw NSError(domain:"ddsError", code:1, userInfo:[
                    NSLocalizedDescriptionKey : NSLocalizedString("Graphics format is not supported.", comment:"DDS: Unknown FourCC"),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file cannot be read because it uses a compressed data format that is not supported. Only DXT1, DXT3 and DXT5 formats are supported.", comment: "DDS: Unknown FourCC")]);
            }
        } else if ((header.pixelFormat.flags & 64) != 0) {  // Use RGB
            
            if header.pixelFormat.flags & 1 != 0 {
                if header.pixelFormat.rgbBitCount == 32 {
                    // Mentally swap the constants!
                    if header.pixelFormat.aBitMask == 0xFF000000 && header.pixelFormat.rBitMask == 0x00FF0000 && header.pixelFormat.gBitMask == 0x0000FF00 && header.pixelFormat.bBitMask == 0x000000FF {
                        dataFormat = .bgra8
                    } else if header.pixelFormat.aBitMask == 0xFF000000 && header.pixelFormat.rBitMask == 0x000000FF && header.pixelFormat.gBitMask == 0x0000FF00 && header.pixelFormat.bBitMask == 0x00FF0000 {
                        dataFormat = .rgba8
                    } else {
                        throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Graphics format is not supported.", comment: "DDS: Unknown 32-bit alpha format"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Only ARGB or ABGR is supported for 32 bit uncompressed textures.", comment: "DDS: Unknown 32-bit format")])
                    }
                } else if header.pixelFormat.rgbBitCount == 16 {
                    if header.pixelFormat.aBitMask == 0x8000 && header.pixelFormat.rBitMask == 0x7C00 && header.pixelFormat.gBitMask == 0x03E0 && header.pixelFormat.bBitMask == 0x001F {
                        dataFormat = .argb1555
                    } else if header.pixelFormat.aBitMask == 0xF000 && header.pixelFormat.rBitMask == 0x0F00 && header.pixelFormat.gBitMask == 0x00F0 && header.pixelFormat.bBitMask == 0x000F {
                        dataFormat = .argb4
                    } else {
                        throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Graphics format is not supported.", comment: "DDS: Unknown 16-bit alpha format"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Only ARGB4 and ARGB1555 are supported for 16 bit uncompressed textures with alpha channel.", comment: "DDS: Unknown 16-bit alpha format")])
                    }
                } else {
                    throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: String(format:NSLocalizedString("%u bits per pixel with alpha are not supported.", comment: "DDS: Unknown alpha bitcount"), header.pixelFormat.rgbBitCount), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Uncompressed formats with alpha have to be 32 or 16 bits per pixel.", comment: "DDS: Unknown alpha bitcount")])
                }
            } else {
                // No alpha
                if header.pixelFormat.rgbBitCount == 32 {
                    if header.pixelFormat.rBitMask == 0x00FF0000 && header.pixelFormat.gBitMask == 0x0000FF00 && header.pixelFormat.bBitMask == 0x000000FF {
                        dataFormat = .bgrx8
                    } else {
                        throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Graphics format is not supported.", comment: "DDS: Unknown 32-bit non-alpha format"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Only XRGB is supported for 32 bit uncompressed textures with alpha.", comment: "DDS: Unknown 32-bit non-alpha format")])
                    }
                } else if header.pixelFormat.rgbBitCount == 24 {
                    if header.pixelFormat.rBitMask == 0x00FF0000 && header.pixelFormat.gBitMask == 0x0000FF00 && header.pixelFormat.bBitMask == 0x000000FF {
                        dataFormat = .bgr8
                    } else {
                        throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Graphics format is not supported.", comment: "DDS: Unknown 24-bit non-alpha format"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Only RGB is supported for 24 bit uncompressed textures.", comment: "DDS: Unknown 24-bit non-alpha format")])
                    }
                } else if header.pixelFormat.rgbBitCount == 16 {
                    if header.pixelFormat.rBitMask == 0xF800 && header.pixelFormat.gBitMask == 0x7E0 && header.pixelFormat.bBitMask == 0x001F {
                        dataFormat = .rgb565
                    } else {
                        throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Graphics format is not supported.", comment: "DDS: Unknown 16-bit non-alpha format"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Only RGB565 is supported for 16 bit uncompressed textures.", comment: "DDS: Unknown 16-bit non-alpha format")])
                    }
                } else {
                    throw NSError(domain: "ddsError", code: 1, userInfo: [NSLocalizedDescriptionKey: String(format:NSLocalizedString("%u bits per pixel without alpha are not supported.", comment: "DDS: Unknown non-alpha bitcount"), header.pixelFormat.rgbBitCount), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("The file uses a data layout that is not supported. Uncompressed formats without alpha have to be 32, 24 or 16 bits per pixel.", comment: "DDS: Unknown non-alpha bitcount")])
                }
            }
        } else {
            throw NSError(domain:"ddsError", code:1, userInfo:[
                    NSLocalizedDescriptionKey : NSLocalizedString("The file's graphics format is not supported.", comment:"DDS: Unknown graphics format"),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Only DXT1,3,5 and uncompressed (A)RGB formats are supported.", comment: "DDS: Unknown graphics format")]);
        }
        
        width = Int(header.width)
        height = Int(header.height)
        numMipmaps = Int(header.mipMapCount)
        
        super.init()
    }
    
    @objc func data(mipmapLevel: Int) -> Data? {
        // Stupid implementation because I have a headache
        var size = 0
        var offset = 0
        var height = self.height
        var width = self.width
        var i = 0
        while i <= mipmapLevel && (width != 0 || height != 0) {
            width = max(width, 1)
            height = max(height, 1)
            
            offset += size
            switch self.dataFormat {
            case .dxt1:
                size = (((width+3)/4) * ((height+3)/4)) * 8
            case .dxt3:
                fallthrough
            case .dxt5:
                size = (((width+3)/4) * ((height+3)/4)) * 16
            case .argb1555:
                fallthrough
            case .argb4:
                fallthrough
            case .rgb565:
                size = width * height * 2
            case .bgr8:
                size = width * height * 3
            case .bgra8:
                fallthrough
            case .rgba8:
                fallthrough
            case .bgrx8:
                size = width * height * 4
            }
            
            width >>= 1
            height >>= 1
            i += 1
        }
        
        if size == 0 {
            return nil
        }
        let dataStart = 4 + MemoryLayout<DDSFileHeader>.size + offset
        if dataStart + size > fileData.count {
            return nil
        }
        
        return fileData[dataStart ..< (dataStart + size)]
    }
}
