//
//  GLLCameraTarget+CoreDataClass.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GLLCameraTarget)
public class GLLCameraTarget: NSManagedObject, Identifiable {
    @NSManaged public var name: String?
    @NSManaged public var bones: NSSet!
    @NSManaged public var cameras: NSSet!

    @objc class var keyPathsForValuesAffectingDisplayName: Set<String> {
        return [#keyPath(name)]
    }
    
    @objc var displayName: String {
        return String(format: NSLocalizedString("%@ - %@", comment: "camera target name format"), name ?? "Target", (bones.anyObject() as? GLLItemBone)?.item?.displayName ?? "Item")
    }
    
    @objc var position: vec_float4 {
        var position = SIMD4<Float32>()
        for bone in self.bones ?? [] {
            position += (bone as! GLLItemBone).globalPosition
        }
        return position / SIMD4<Float32>(repeating: Float(self.bones.count))
    }
}
