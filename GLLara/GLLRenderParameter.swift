//
//  GLLRenderParameter.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

import Foundation
import CoreData

/*!
 * @abstract Stores the value of a render parameter.
 * @discussion A render parameter is a term from XNALara. It means any uniform
 * variable that is set on a per-mesh basis. GLLara allows adjusting them after
 * loading, so they are represented in the data model.
 */
@objc(GLLRenderParameter)
public class GLLRenderParameter: NSManagedObject {
    @NSManaged public var name: String!
    @NSManaged public var mesh: GLLItemMesh!
    
    @objc class var keyPathsForValuesAffectingDescription: Set<String> {
        return [#keyPath(name)]
    }
    
    @objc var parameterDescription: GLLRenderParameterDescription? {
        return mesh.mesh.shader?.description(forParameter: name)
    }
}
