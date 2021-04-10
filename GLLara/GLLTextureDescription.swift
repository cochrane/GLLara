//
//  GLLTextureDescription.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLTextureDescription: NSObject, Decodable {
    @objc let localizedTitle: String
    @objc let localizedDescription: String
    
    @objc init(withPlist dictionary: [String: Any]) {
        self.localizedTitle = Bundle.main.localizedString(forKey: dictionary["title"] as? String ?? "", value: nil, table: "Textures")
        self.localizedDescription = Bundle.main.localizedString(forKey: dictionary["description"] as? String ?? "", value: nil, table: "Textures")
    }
    
    enum PlistCodingKeys: String, CodingKey {
        case title, description
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PlistCodingKeys.self)
        let titleKey = try container.decode(String.self, forKey: .title)
        self.localizedTitle = Bundle.main.localizedString(forKey: titleKey, value: nil, table: "Textures")
        let descriptionKey = try container.decode(String.self, forKey: .description)
        self.localizedDescription = Bundle.main.localizedString(forKey: descriptionKey, value: nil, table: "Textures")

    }
}
