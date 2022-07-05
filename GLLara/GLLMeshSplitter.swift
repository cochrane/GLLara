//
//  GLLMeshSplitter.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

class GLLMeshSplitter: Decodable {
    let min: [Double]
    let max: [Double]
    let splitPartName: String
    
    enum CodingKeys: String, CodingKey {
        case minX
        case minY
        case minZ
        case maxX
        case maxY
        case maxZ
        case Name
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        min = [try container.decodeIfPresent(Double.self, forKey: .minX) ?? -Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .minY) ?? -Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .minZ) ?? -Double.infinity]
        
        max = [try container.decodeIfPresent(Double.self, forKey: .maxX) ?? Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .maxY) ?? Double.infinity,
               try container.decodeIfPresent(Double.self, forKey: .maxZ) ?? Double.infinity]
        
        splitPartName = try container.decode(String.self, forKey: .Name)
    }
}
