//
//  GLLItemOptionalPartMarker.swift
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Foundation

/**
 * A simple object that only contains a GLLItem; used for selection to mark that
 * the "optional parts" section was selected.
 *
 * Equality and hash code: Two of these are equal - and have equal hash codes -
 * if the underlying items are.
 */
@objc class GLLItemOptionalPartMarker: NSObject {
    @objc init(item: GLLItem) {
        self.item = item
    }
    
    @objc let item: GLLItem
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? GLLItemOptionalPartMarker else {
            return false
        }
        return self.item == other.item
    }

    override var hash: Int {
        return item.hash
    }
}
