//
//  GLLItemBoneExtensions.swift
//  GLLara
//
//  Created by Torsten Kammer on 02.08.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

extension GLLItemBone {
    
    func parent(skippingUnused: Bool) -> GLLItemBone? {
        var usedParent = self.parent
        while let current = usedParent {
            if !skippingUnused || !current.bone.name.hasPrefix("unused") {
                return current
            }
            usedParent = current.parent
        }
        return nil
    }
    
    func children(skippingUnused: Bool) -> [GLLItemBone] {
        guard let children = children else {
            return []
        }
        var result: [GLLItemBone] = []
        for child in children {
            if skippingUnused && child.bone.name.hasPrefix("unused") {
                result.append(contentsOf: child.children(skippingUnused: true))
            } else {
                result.append(child)
            }
        }
        return result
    }
    
    func firstChild(skippingUnused: Bool) -> GLLItemBone? {
        guard let children = children else {
            return nil
        }
        for child in children {
            if skippingUnused && child.bone.name.hasPrefix("unused") {
                if let usedDescendant = child.firstChild(skippingUnused: true) {
                    return usedDescendant
                }
            } else {
                return child
            }
        }
        return nil
    }
    
    func siblings(skippingUnused: Bool) -> [GLLItemBone]? {
        return parent(skippingUnused: skippingUnused)?.children(skippingUnused: skippingUnused)
    }
    
    @objc static func rotationMatrix(angles: simd_float3) -> matrix_float4x4 {
        let sin = sin(angles)
        let cos = cos(angles)
        
        /*
         Rotation order:
         
         mat_float16 transform = simd_mat_rotate(self.rotationY, simd_e_y);
         transform = simd_mul(transform, simd_mat_rotate(self.rotationX, simd_e_x));
         transform = simd_mul(transform, simd_mat_rotate(self.rotationZ, simd_e_z));
         
         Required by XNALara compatibility
         
         Worked out by hand to:
             cos(y)*cos(z)+sin(x)*sin(y)*sin(z)     -cos(y)*sin(z)+sin(x)*sin(y)*cos(z)       cos(x)*sin(y)
             cos(x)*sin(z)                          cos(x)*cos(z)                             -sin(x)
             -sin(y)*cos(z)+sin(x)*cos(y)*sin(z)    sin(y)*sin(z)+sin(x)*cos(y)*cos(z)        cos(x)*cos(y)
         */
        
        // Parameters are columns so they look transposed here
        return matrix_float4x4(SIMD4<Float>(cos.y*cos.z+sin.x*sin.y*sin.z, cos.x*sin.z, -sin.y*cos.z+sin.x*cos.y*sin.z, 0.0),
                               SIMD4<Float>(-cos.y*sin.z+sin.x*sin.y*cos.z, cos.x*cos.z, sin.y*sin.z+sin.x*cos.y*cos.z, 0.0),
                               SIMD4<Float>(cos.x*sin.y, -sin.x, cos.x*cos.y, 0.0),
                               SIMD4<Float>(0, 0, 0, 1))
    }
    
    @objc static func eulerAngles(rotationMatrix: matrix_float4x4) -> simd_float3 {
        /*
         Getting the angles from the matrix above, so:
         -sin(x) = c2.r1 => x = asin(-c2.r1)
         
         If cos(x) != 0:
         => tan(y) = (c2.r0/cos(x)) / (c2.r2/cos(x))
            tan(z) = (c0.r1/cos(x)) / (c1.r1/cos(x))

         If cos(x) == 0:
             If sin(x) == +1:
                c0.r0 = cos(y)cos(z)+sin(y)sin(z) = cos(y-z)=cos(z-y)
                c0.r2 = cos(y)sin(z)-sin(y)cos(z) = sin(z-y)
                c1.r0 = sin(y)cos(z)-cos(y)sin(z) = sin(y-z) = -c0.r2
                c1.r2 = sin(y)sin(z)+cos(y)cos(z) = c0.r0
                => set z=0, then tan(y)=sin(y-z)/cos(y-z) => y = atan2(c1.r0, c1.r2)
             If sin(x) == -1:
                c0.r0 = cos(y)cos(z)-sin(y)sin(z) = cos(y+z)
                c0.r2 = -sin(y)cos(z)-cos(y)sin(z) = -sin(y+z)
                c1.r0 = -cos(y)sin(z)-sin(y)cos(z) = c0.r2
                c1.r2 = sin(y)sin(z)-cos(y)cos(z) = -c0.r0
                => set z=0, then tan(y)=sin(y+z)/cos(y+z) => y = atan2(-c0.r2, c0.r0)
         */
        let sinx = -rotationMatrix.columns.2.y
        let x = asin(sinx)
        let y: Float
        let z: Float
        let cosx = cos(x)
        if abs(cosx) > 1e-6 { // TODO epsilon
            y = atan2(rotationMatrix.columns.2.x/cosx, rotationMatrix.columns.2.z/cosx);
            z = atan2(rotationMatrix.columns.0.y/cosx, rotationMatrix.columns.1.y/cosx);
        } else {
            z = 0
            if sinx > 0 {
                y = atan2(rotationMatrix.columns.1.x, rotationMatrix.columns.1.z)
            } else {
                y = atan2(-rotationMatrix.columns.0.z, rotationMatrix.columns.0.x)
            }
        }
        return SIMD3<Float>(x, y, z);
    }
    
}
