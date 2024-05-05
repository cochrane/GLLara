//
//  GLLAmbientLight+CoreDataClass.swift
//  GLLara
//
//  Created by Torsten Kammer on 05.05.24.
//  Copyright © 2024 Torsten Kammer. All rights reserved.
//
//

import Foundation
import CoreData

/**
 * @abstract A scene's ambient light information.
 * @discussion Each scene will have only one. The index is only for sorting in
 * the UI.
 */
@objc(GLLAmbientLight)
public class GLLAmbientLight: NSManagedObject {
    @NSManaged public var color: NSColor!
    @NSManaged public var index: Int64
}
