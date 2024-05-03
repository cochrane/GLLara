//
//  GLLItemMeshTexture+CoreDataClass.swift
//  GLLara
//
//  Created by Torsten Kammer on 03.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GLLItemMeshTexture)
public class GLLItemMeshTexture: NSManagedObject {
    
    // Get URL from bookmark
    @objc public override func awakeFromFetch() {
        if let data = textureBookmarkData {
            var stale = false
            if let textureUrl = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) {
                self.setPrimitiveValue(textureUrl, forKey: "textureURL")
            }
        }
    }
    
    @objc public override func willSave() {
        // Put URL into bookmark
        if let url = self.primitiveValue(forKey: "textureURL") as? NSURL {
            let textureUrl = url as URL
            if let bookmark = try? textureUrl.bookmarkData() {
                self.setPrimitiveValue(bookmark, forKey: "textureBookmarkData")
            }
        } else {
            self.setPrimitiveValue(nil, forKey: "textureBookmarkData")
        }
    }
    
    @objc var texCoordSet: Int {
        set {
            willChangeValue(for: \.texCoordSet)
            setPrimitiveValue(NSNumber(value: newValue), forKey: "texCoordSet")
            mesh?.updateShader()
            didChangeValue(for: \.texCoordSet)
        }
        get {
            return (primitiveValue(forKey: "texCoordSet") as! NSNumber).intValue
        }
    }
    
    @objc var textureDescription: GLLTextureDescription? {
        guard let identifier, let mesh, let shader = mesh.mesh.shader else {
            return nil
        }
        return shader.description(forTexture: identifier)
    }
}

extension GLLItemMeshTexture {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GLLItemMeshTexture> {
        return NSFetchRequest<GLLItemMeshTexture>(entityName: "GLLItemMeshTexture")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var textureBookmarkData: Data?
    @NSManaged public var textureURL: NSURL?
    @NSManaged public var mesh: GLLItemMesh?
}
