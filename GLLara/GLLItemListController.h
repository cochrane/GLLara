//
//  GLLItemListController.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "GLLSourceListItem.h"

/*!
 * The root for the items list in the outline view. What this code actually does is manage a list of GLLItemController instances that gets updated whenever necessary.
 */
@interface GLLItemListController : NSObject <GLLSourceListItem>

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end
