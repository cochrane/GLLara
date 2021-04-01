//
//  GLLDocumentTest.m
//  GLLara
//
//  Created by Torsten Kammer on 08.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentTest.h"

#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLResourceManager.h"

#import <Cocoa/Cocoa.h>

static NSURL *testModelURL;
static NSURL *testDocumentURL;

@implementation GLLDocumentTest

+ (void)initialize
{
    testModelURL = [[NSBundle bundleForClass:self] URLForResource:@"generic_item" withExtension:@"mesh.ascii"];
    
    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    testDocumentURL = [NSURL URLWithString:[[[NSBundle bundleForClass:self] bundleIdentifier] stringByAppendingFormat:@"-testdocument.gllsc"] relativeToURL:temporaryDirectoryURL];
}

- (void)tearDown
{
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[NSFileManager defaultManager] removeItemAtURL:testDocumentURL error:NULL];
    for (NSDocument *doc in [[NSDocumentController sharedDocumentController] documents])
        [doc close];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[GLLResourceManager sharedResourceManager] clearInternalCaches];
}

- (void)testCreateSaveCloseLoad
{
    NSError *error = nil;
    GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
    
    XCTAssertNotNil(doc, @"Should open empty document");
    XCTAssertNil(error, @"Should not have error (got %@)", error);
    
    error = nil;
    GLLItem *item = [doc addModelAtURL:testModelURL error:&error];
    XCTAssertNotNil(item, @"Should have added model");
    XCTAssertNil(error, @"Should not have error (got %@)", error);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    __block BOOL completedOuter = NO;
    [doc saveToURL:testDocumentURL ofType:@"Scene" forSaveOperation:NSSaveOperation completionHandler:^(NSError *errorOrNil){
        XCTAssertNil(errorOrNil, @"Should save without error");
        
        [doc close];
        
        __block BOOL completedInner = NO;
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:testDocumentURL display:YES completionHandler:^(NSDocument *document, BOOL wasAlreadyOpen, NSError *error){
            XCTAssertNil(error, @"Shouldn't have had an error, got %@", error);
            XCTAssertFalse(wasAlreadyOpen, @"Should have been closed");
            XCTAssertNotNil(document, @"Should have a document here");
            XCTAssertTrue([document isKindOfClass:[GLLDocument class]], @"Wrong document subclass");
            completedInner = YES;
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
            NSArray *items = [((GLLDocument *)document).managedObjectContext executeFetchRequest:request error:NULL];
            XCTAssertEqual(items.count, 1UL, @"Should have one item");
            XCTAssertEqualObjects([[items objectAtIndex:0] itemURL], testModelURL, @"Should have test model URL");
            
            [document close];
        }];
        while (!completedInner)
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
        completedOuter = YES;
    }];
    while (!completedOuter)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

- (void)testCreateRemoveSave
{
    /*
     * Verify fixes for:
     * - https://github.com/cochrane/GLLara/issues/57
     * - https://github.com/cochrane/GLLara/issues/48
     */
    NSError *error = nil;
    GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
    
    XCTAssertNotNil(doc, @"Should open empty document");
    XCTAssertNil(error, @"Should not have error (got %@)", error);
    
    error = nil;
    GLLItem *item = [doc addModelAtURL:testModelURL error:&error];
    XCTAssertNotNil(item, @"Should have added model");
    XCTAssertNil(error, @"Should not have error (got %@)", error);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [doc.managedObjectContext deleteObject:item];
    
    __block BOOL doneWithOuter = NO;
    [doc saveToURL:testDocumentURL ofType:@"Scene" forSaveOperation:NSSaveOperation completionHandler:^(NSError *errorOrNil){
        XCTAssertNil(errorOrNil, @"Should save without error");
        
        [doc close];
        
        __block BOOL doneWithInner = NO;
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:testDocumentURL display:YES completionHandler:^(NSDocument *document, BOOL wasAlreadyOpen, NSError *error){
            XCTAssertNil(error, @"Shouldn't have had an error, got %@", error);
            XCTAssertFalse(wasAlreadyOpen, @"Should have been closed");
            XCTAssertNotNil(document, @"Should have a document here");
            XCTAssertTrue([document isKindOfClass:[GLLDocument class]], @"Wrong document subclass");
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
            NSArray *items = [((GLLDocument *)document).managedObjectContext executeFetchRequest:request error:NULL];
            XCTAssertEqual(items.count, 0UL, @"Should have no item");
            
            doneWithInner = YES;
            
            [document close];
        }];
        while (!doneWithInner)
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
        doneWithOuter = YES;
    }];
    while (!doneWithOuter)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

- (void)testBoneRotationLimit
{
    // Issue #61
    float rotationNearLimit = M_PI*2.0 - 0.0001;
    
    NSError *error = nil;
    GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
    
    XCTAssertNotNil(doc, @"Should open empty document");
    XCTAssertNil(error, @"Should not have error (got %@)", error);
    
    error = nil;
    GLLItem *item = [doc addModelAtURL:testModelURL error:&error];
    XCTAssertNotNil(item, @"Should have added model");
    XCTAssertNil(error, @"Should not have error (got %@)", error);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [item.bones[0] setRotationY:rotationNearLimit];
    [item.bones[0] setRotationZ:1.0f];
    
    __block BOOL completedOuter = NO;
    [doc saveToURL:testDocumentURL ofType:@"Scene" forSaveOperation:NSSaveOperation completionHandler:^(NSError *errorOrNil){
        XCTAssertNil(errorOrNil, @"Should save without error");
        
        [doc close];
        
        __block BOOL completedInner = NO;
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:testDocumentURL display:YES completionHandler:^(NSDocument *document, BOOL wasAlreadyOpen, NSError *error){
            XCTAssertNil(error, @"Shouldn't have had an error, got %@", error);
            XCTAssertFalse(wasAlreadyOpen, @"Should have been closed");
            XCTAssertNotNil(document, @"Should have a document here");
            XCTAssertTrue([document isKindOfClass:[GLLDocument class]], @"Wrong document subclass");
            completedInner = YES;
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
            NSArray *items = [((GLLDocument *)document).managedObjectContext executeFetchRequest:request error:NULL];
            XCTAssertEqual(items.count, 1UL, @"Should have one item");
            XCTAssertEqualObjects([[items objectAtIndex:0] itemURL], testModelURL, @"Should have test model URL");
            XCTAssertEqualWithAccuracy([item.bones[0] rotationY], rotationNearLimit, 0.0001, @"Should have kept rotation near limit exactly.");
            XCTAssertEqual([item.bones[0] rotationZ], 1.0f, @"Should have kept rotation far from limit exactly.");
            
            
            [document close];
        }];
        while (!completedInner)
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
        completedOuter = YES;
    }];
    while (!completedOuter)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

@end
