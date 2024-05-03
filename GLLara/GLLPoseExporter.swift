//
//  GLLPoseExporter.m
//  GLLara
//
//  Created by Torsten Kammer on 31.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

import Foundation

/*!
 * @abstract Exports a pose for a complete item or just a few bones.
 * @discussion Since it can export a pose for only a few bones, this
 * functionality does not belong to the item.
 */
@objc class GLLPoseExporter: NSObject {
    @objc convenience init(item: GLLItem) {
        self.init(bones: item.combinedBones()!.map { $0 as! GLLItemBone })
    }
    
    @objc init(bones: [GLLItemBone]) {
        bonesList = bones
        
        super.init()
    }
    
    let bonesList: [GLLItemBone]
    
    @objc var skipUnused = false
    
    @objc var poseDescription: String {
        var result = ""
        for bone in bonesList {
            if skipUnused && bone.bone.name.hasPrefix("unused") {
                continue
            }
            
            result += "\(bone.bone.name): \(bone.rotationX * 180/Float.pi) \(bone.rotationY * 180/Float.pi) \(bone.rotationZ * 180/Float.pi) \(bone.positionX) \(bone.positionY) \(bone.positionZ)\r\n"
        }
        return result
    }
}
