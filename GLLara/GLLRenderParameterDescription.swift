//
//  GLLRenderParameterDescription.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc enum GLLRenderParameterType: Int, Decodable {
    case color
    case float
}

@objc class GLLRenderParameterDescription: NSObject, Decodable {
    @objc let min: Double
    @objc let max: Double
    @objc let localizedTitle: String
    @objc let localizedDescription: String
    
    @objc let type: GLLRenderParameterType
    
    @objc init(withPlist dictionary: [String: Any]) {
        self.min = dictionary["min"] as? Double ?? 0
        self.max = dictionary["max"] as? Double ?? 0
        self.localizedTitle = Bundle.main.localizedString(forKey: dictionary["title"] as! String, value: nil, table: "RenderParameters")
        self.localizedDescription = Bundle.main.localizedString(forKey: dictionary["description"] as! String, value: nil, table: "RenderParameters")
        
        self.type = dictionary["type"] as? String == "color" ? .color : .float
    }
    
    enum PlistCodingKeys: String, CodingKey {
        case min, max, title, description, type
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PlistCodingKeys.self)
        self.min = try container.decode(Double.self, forKey: .min)
        self.max = try container.decode(Double.self, forKey: .max)
        
        let titleKey = try container.decode(String.self, forKey: .title)
        self.localizedTitle = Bundle.main.localizedString(forKey: titleKey, value: nil, table: "RenderParameters")
        
        let descriptionKey = try container.decode(String.self, forKey: .description)
        self.localizedDescription = Bundle.main.localizedString(forKey: descriptionKey, value: nil, table: "RenderParameters")
        
        let typeValue = try container.decodeIfPresent(String.self, forKey: .type)
        if typeValue == "color" {
            self.type = .color
        } else {
            self.type = .float
        }
    }
    
    override var hash: Int {
        var hash = Int(min)
        hash = 31 * hash + Int(max)
        hash = 31 * hash + localizedDescription.hash
        hash = 31 * hash + localizedTitle.hash
        hash = 31 * hash + type.rawValue
        return hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? GLLRenderParameterDescription {
            return self == other
        }
        return false
    }
    
    static func == (lhs: GLLRenderParameterDescription, rhs: GLLRenderParameterDescription) -> Bool {
        return lhs.min == rhs.min && lhs.max == rhs.max && lhs.localizedTitle == rhs.localizedTitle && lhs.localizedDescription == rhs.localizedDescription && lhs.type == rhs.type
    }
}
