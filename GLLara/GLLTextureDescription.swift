//
//  GLLTextureDescription.swift
//  GLLara
//
//  Created by Torsten Kammer on 10.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

@objc class GLLTextureDescription: NSObject, Decodable {
    var title: String
    var descriptionKey: String
    var optionalXnaLaraTexCoordSet: Int?
    
    @objc var xnaLaraTexCoordSet: Int {
        return optionalXnaLaraTexCoordSet ?? 0
    }
    
    @objc lazy var localizedTitle: String = Bundle.main.localizedString(forKey: self.title, value: nil, table: "Textures")
    
    @objc lazy var localizedDescription: String = Bundle.main.localizedString(forKey: self.descriptionKey, value: nil, table: "Textures")
    
    enum CodingKeys: String, CodingKey {
        case title, descriptionKey = "description", optionalXnaLaraTexCoordSet = "xnaLaraTexCoordSet"
    }
}
