//
//  GLLRenderParameter.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLMeshSettings;
@class GLLRenderParameterDescription;

@interface GLLRenderParameter : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) GLLMeshSettings *mesh;

@property (nonatomic, retain, readonly) GLLRenderParameterDescription *parameterDescription;

@property (nonatomic, readonly) NSData *uniformValue;

@end
