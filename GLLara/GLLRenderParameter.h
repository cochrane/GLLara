//
//  GLLRenderParameter.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLItem;
@class GLLItemMesh;
@class GLLRenderParameterDescription;

/*!
 * @abstract Stores the value of a render parameter.
 * @discussion A render parameter is a term from XNALara. It means any uniform
 * variable that is set on a per-mesh basis. GLLara allows adjusting them after
 * loading, so they are represented in the data model.
 */
@interface GLLRenderParameter : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) GLLItemMesh *mesh;

@property (nonatomic, retain, readonly) GLLRenderParameterDescription *parameterDescription;

@property (nonatomic, readonly) NSData *uniformValue;

@end
