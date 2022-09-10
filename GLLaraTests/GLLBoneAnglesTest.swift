//
//  GLLBoneAnglesTest.swift
//  GLLaraTests
//
//  Created by Torsten Kammer on 10.09.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import XCTest

class GLLBoneAnglesTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    static func assertEqual(a: SIMD4<Float>, b: SIMD4<Float>, accuracy: SIMD4<Float>) {
        // Do top-level check with SIMD
        if any(abs(a-b) .>= accuracy) {
            // Failed. Assert individual components so we get better error messages
            XCTAssertEqual(a.x, b.x, accuracy: accuracy.x)
            XCTAssertEqual(a.y, b.y, accuracy: accuracy.y)
            XCTAssertEqual(a.z, b.z, accuracy: accuracy.z)
            XCTAssertEqual(a.w, b.w, accuracy: accuracy.w)
        }
    }
    
    static func compareMatrix(a: simd_float4x4, b: simd_float4x4, accuracy: SIMD4<Float>) {
        assertEqual(a: a.columns.0, b: b.columns.0, accuracy: accuracy)
        assertEqual(a: a.columns.1, b: b.columns.1, accuracy: accuracy)
        assertEqual(a: a.columns.2, b: b.columns.2, accuracy: accuracy)
        assertEqual(a: a.columns.3, b: b.columns.3, accuracy: accuracy)
    }

    static func compareMatrices(angles: SIMD3<Float>) {
        let matrix = GLLItemBone.rotationMatrix(angles: angles)
        let angles = GLLItemBone.eulerAngles(rotationMatrix: matrix)
        let restoredMatrix = GLLItemBone.rotationMatrix(angles: angles)
        
        let accuracy = SIMD4<Float>(repeating: 1e-5)
        GLLBoneAnglesTest.compareMatrix(a: matrix, b: restoredMatrix, accuracy: accuracy)
    }
    
    func testAngles() async throws {
        await withTaskGroup(of: Void.self) { group in
            for x in stride(from: -Float.pi, through: Float.pi, by: Float(0.1)) {
                group.addTask {
                    for y in stride(from: -Float.pi, through: Float.pi, by: Float(0.1)) {
                        for z in stride(from: -Float.pi, through: Float.pi, by: Float(0.1)) {
                            GLLBoneAnglesTest.compareMatrices(angles: SIMD3<Float>(x: x, y: y, z: z))
                        }
                    }
                }
            }
        }
    }
    
    func testSpecificAngles() async throws {
        let piAngles: [Float] = stride(from: Float(-2.5), through: Float(+2.5), by: Float(0.5)).map { $0 * Float.pi }
        let otherAngles: [Float] = [ -1, -0.5, -0.1, 0, 0.1, 0.5, 1 ]
        
        let combinedInterestingAngles = piAngles + otherAngles
        
        await withTaskGroup(of: Void.self) { group in
            for x in combinedInterestingAngles {
                group.addTask {
                    for y in combinedInterestingAngles {
                        for z in combinedInterestingAngles {
                            GLLBoneAnglesTest.compareMatrices(angles: SIMD3<Float>(x: x, y: y, z: z))
                        }
                    }
                }
            }
        }
    }
    
    func testMatrixX() async throws {
        let piAngles = stride(from: Float(-2.5), through: Float(+2.5), by: Float(0.5)).map { $0 * Float.pi }
        let otherAngles = stride(from: -Float.pi, through: Float.pi, by: 0.1)
        let allAngles = piAngles + otherAngles
        
        for x in allAngles {
            let matrix = GLLItemBone.rotationMatrix(angles: SIMD3<Float>(x: x, y: 0, z: 0))
            
            let baseVector = normalize(SIMD4<Float>(0.0, 1.0, 0.5, 0.0))
            let rotated = matrix * baseVector
            
            let cosAngle = dot(baseVector, rotated)
            XCTAssertEqual(cosAngle, cos(x), accuracy: 1e-5)
            XCTAssertEqual(rotated.x, 0, accuracy: 1e-5)
            
            let rotated2 = matrix * SIMD4<Float>(0.0, 1.0, 0.0, 0.0)
            XCTAssertEqual(rotated2.y, cos(x), accuracy: 1e-5)
            XCTAssertEqual(rotated2.z, sin(x), accuracy: 1e-5)
        }
    }
    
    func testMatrixY() async throws {
        let piAngles = stride(from: Float(-2.5), through: Float(+2.5), by: Float(0.5)).map { $0 * Float.pi }
        let otherAngles = stride(from: -Float.pi, through: Float.pi, by: 0.1)
        let allAngles = piAngles + otherAngles
        
        for y in allAngles {
            let matrix = GLLItemBone.rotationMatrix(angles: SIMD3<Float>(x: 0, y: y, z: 0))
            
            let baseVector = normalize(SIMD4<Float>(1.0, 0.0, -1.0, 0.0))
            let rotated = matrix * baseVector
            
            let cosAngle = dot(baseVector, rotated)
            XCTAssertEqual(cosAngle, cos(y), accuracy: 1e-5)
            XCTAssertEqual(rotated.y, 0, accuracy: 1e-5)
            
            let rotated2 = matrix * SIMD4<Float>(1.0, 0.0, 0.0, 0.0)
            XCTAssertEqual(rotated2.x, cos(y), accuracy: 1e-5)
            XCTAssertEqual(rotated2.z, -sin(y), accuracy: 1e-5)
        }
    }
    
    func testMatrixZ() async throws {
        let piAngles = stride(from: Float(-2.5), through: Float(+2.5), by: Float(0.5)).map { $0 * Float.pi }
        let otherAngles = stride(from: -Float.pi, through: Float.pi, by: 0.1)
        let allAngles = piAngles + otherAngles
        
        for z in allAngles {
            let matrix = GLLItemBone.rotationMatrix(angles: SIMD3<Float>(x: 0, y: 0, z: z))
            
            let baseVector = normalize(SIMD4<Float>(1.0, 1.0, 0.0, 0.0))
            let rotated = matrix * baseVector
            
            let cosAngle = dot(baseVector, rotated)
            XCTAssertEqual(cosAngle, cos(z), accuracy: 1e-5)
            XCTAssertEqual(rotated.z, 0, accuracy: 1e-5)
            
            let rotated2 = matrix * SIMD4<Float>(1.0, 0.0, 0.0, 0.0)
            XCTAssertEqual(rotated2.x, cos(z), accuracy: 1e-5)
            XCTAssertEqual(rotated2.y, sin(z), accuracy: 1e-5)
        }
    }

}
