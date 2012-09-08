//
//  GLLAmbientLight.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "GLLSourceListItem.h"

@interface GLLAmbientLight : NSManagedObject <GLLSourceListItem>

@property (nonatomic, retain) NSColor *color;
@property (nonatomic) NSUInteger index;

@end
