//
//  GLLLightController.h
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * Source list controller for a single light (whether diffuse or ambient).
 */
@interface GLLLightController : NSObject

- (id)initWithLight:(NSManagedObject *)light parentController:(id)parentController;

@property (nonatomic, readonly) NSManagedObject *light;
@property (nonatomic, readonly) id representedObject;
@property (nonatomic, weak) id parentController;

@end
