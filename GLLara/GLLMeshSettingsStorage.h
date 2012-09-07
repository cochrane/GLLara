//
//  GLLMeshSettingsStorage.h
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLItemStorage;

@interface GLLMeshSettingsStorage : NSManagedObject

@property (nonatomic) BOOL isVisible;
@property (nonatomic) int64_t meshIndex;
@property (nonatomic, retain) GLLItemStorage *item;

@end
