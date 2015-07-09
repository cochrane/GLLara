//
//  GLLExportBinaryTest.h
//  GLLara
//
//  Created by Torsten Kammer on 27.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

@interface GLLExportBinaryTest : XCTestCase

@property (nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end
