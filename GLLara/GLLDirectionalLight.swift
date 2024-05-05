//
//  GLLDirectionalLight+CoreDataClass.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//
//

import Foundation
import CoreData

/**
 * @abstract A directional light.
 * @discussion Each scene will have three that can be enabled or disabled. The
 * entity stores all the relevant information and can put them in a format
 * useable by the shaders.
 */
@objc(GLLDirectionalLight)
public class GLLDirectionalLight: NSManagedObject {
    @NSManaged public var isEnabled: Bool
    @NSManaged public var latitude: Float32
    @NSManaged public var longitude: Float32
    @NSManaged public var diffuseColor: NSColor!
    @NSManaged public var specularColor: NSColor!
    @NSManaged public var index: Int64
    
    @objc class var keyPathsForValuesAffectingUniformBlock: Set<String> {
        return [#keyPath(isEnabled), #keyPath(latitude), #keyPath(longitude), #keyPath(diffuseColor), #keyPath(specularColor)]
    }
    
    @objc var uniformBlock: GLLLightBuffer {
        let direction = simd_mul(simd_mat_euler(SIMD4<Float32>(x: self.latitude, y: self.longitude, z: 0, w: 0), SIMD4<Float32>(x: 0, y: 0, z: 0, w: 1)), SIMD4<Float32>(x: 0, y: 0, z: -1, w: 0))

        if !isEnabled {
            return GLLLightBuffer(diffuseColor: SIMD4<Float32>(), specularColor: SIMD4<Float32>(), direction: direction)
        }
        
        return GLLLightBuffer(diffuseColor: diffuseColor.rgbaComponents128Bit, specularColor: specularColor.rgbaComponents128Bit, direction: direction)
    }
}
