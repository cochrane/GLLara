//
//  GLLMeshSplitter.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLMeshSplitter: NSObject, Decodable {
    @objc let min: [Double]
    @objc let max: [Double]
    @objc let splitPartName: String
    
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
        
        min = [try container.decodeIfPresent(Double.self, forKey: .minX) ?? -Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .minY) ?? -Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .minZ) ?? -Double.infinity]
        
        max = [try container.decodeIfPresent(Double.self, forKey: .maxX) ?? Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .maxY) ?? Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .maxZ) ?? Double.infinity]
        
        splitPartName = try container.decode(String.self, forKey: .splitPartName)
    }
    
    @objc init(withPlist dictionary: [String: Any]) {
        splitPartName = dictionary["Name"] as! String
        min = [dictionary["minX"] as? Double ?? -Double.infinity,
               dictionary["minY"] as? Double ?? -Double.infinity,
               dictionary["minZ"] as? Double ?? -Double.infinity]
        max = [dictionary["maxX"] as? Double ?? Double.infinity,
               dictionary["maxY"] as? Double ?? Double.infinity,
               dictionary["maxZ"] as? Double ?? Double.infinity]
    }
}
