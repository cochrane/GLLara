//
//  GLLTextureDescriptor.swift
//  GLLara
//
//  Created by Torsten Kammer on 12.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

import Foundation

/**
 Describes a texture assignment in a model file. Either an URL to an image file, or the image data directly, for cases where the image is integrated directly into the model file.
 
 An object must have either an URL or a data object. TODO turn this into an enum once all users are Swift
 
 TODO This could be extended to include Mime-Types
 */
@objc class GLLTextureAssignment: NSObject {
    @objc let url: URL?
    @objc let data: Data?
    
    @objc init(url: URL) {
        self.url = url
        self.data = nil
    }
    
    @objc init(data: Data) {
        self.data = data
        self.url = nil
    }
}
