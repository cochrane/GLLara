//
//  GLLItem+MeshExport.swift
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItem {
    
    @objc func writeBinary() throws -> Data {
        let stream = TROutDataStream()
        
        stream.appendUint32(UInt32(bones.count))
        for bone in bones {
            stream.appendData((bone as! GLLItemBone).bone.writeBinary())
        }
        
        var count: UInt32 = 0
        for mesh in meshes {
            if (mesh as! GLLItemMesh).shouldExport {
                count += 1
            }
        }
        stream.appendUint32(count)
        for mesh in meshes {
            let itemMesh = mesh as! GLLItemMesh
            if itemMesh.shouldExport {
                try stream.appendData(itemMesh.writeBinary())
            }
        }
        
        return stream.data()!;
    }
    
    @objc func writeASCII() throws -> String {
        var string = ""
        
        string += "\(bones.count)\n"
        for bone in bones {
            string += (bone as! GLLItemBone).bone.writeASCII()
            string += "\n"
        }
        
        var count = 0
        for mesh in meshes {
            if (mesh as! GLLItemMesh).shouldExport {
                count += 1
            }
        }
        string += "\(count)\n"
        for mesh in meshes {
            let itemMesh = mesh as! GLLItemMesh
            if itemMesh.shouldExport {
                string += try itemMesh.writeASCII()
                string += "\n"
            }
        }
        
        return string;
    }
    
}
