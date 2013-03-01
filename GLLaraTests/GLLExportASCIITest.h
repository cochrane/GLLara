//
//  GLLExportASCIITest.h
//  GLLara
//
//  Created by Torsten Kammer on 27.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <CoreData/CoreData.h>

@interface GLLExportASCIITest : SenTestCase

@property (nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end
