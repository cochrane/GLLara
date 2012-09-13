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

@interface GLLRenderParameter : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) GLLItemMesh *mesh;

@property (nonatomic, retain, readonly) GLLRenderParameterDescription *parameterDescription;

@property (nonatomic, readonly) NSData *uniformValue;

// The corresponding item
@property (nonatomic, readonly) GLLItem *item;

@end
