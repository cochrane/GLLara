//
//  GLLMeshSplitter.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLMeshSplitter: NSObject, Decodable {
    @objc var min: [Double]
    @objc var max: [Double]
    @objc var splitPartName: String
    
    enum CodingKeys: String, CodingKey {
        case minX
        case minY
        case minZ
        case maxX
        case maxY
        case maxZ
        case splitPartName
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        min = [-Double.infinity, -Double.infinity, -Double.infinity]
        max = [Double.infinity, Double.infinity, Double.infinity]
        
        min[0] = try container.decodeIfPresent(Double.self, forKey: .minX) ?? -Double.infinity
        min[1] = try container.decodeIfPresent(Double.self, forKey: .minY) ?? -Double.infinity
        min[2] = try container.decodeIfPresent(Double.self, forKey: .minZ) ?? -Double.infinity
        
        max[0] = try container.decodeIfPresent(Double.self, forKey: .maxX) ?? Double.infinity
        max[1] = try container.decodeIfPresent(Double.self, forKey: .maxY) ?? Double.infinity
        max[2] = try container.decodeIfPresent(Double.self, forKey: .maxZ) ?? Double.infinity
        
        splitPartName = try container.decode(String.self, forKey: .splitPartName)
    }
    
    @objc init(withPlist dictionary: [String: Any]) {
        splitPartName = dictionary["Name"] as! String
        min = [-Double.infinity, -Double.infinity, -Double.infinity]
        max = [Double.infinity, Double.infinity, Double.infinity]
        min[0] = dictionary["minX"] as? Double ?? -Double.infinity
        min[1] = dictionary["minY"] as? Double ?? -Double.infinity
        min[2] = dictionary["minZ"] as? Double ?? -Double.infinity
        max[0] = dictionary["maxX"] as? Double ?? -Double.infinity
        max[1] = dictionary["maxY"] as? Double ?? -Double.infinity
        max[2] = dictionary["maxZ"] as? Double ?? -Double.infinity
    }
}
