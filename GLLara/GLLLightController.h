//
//  GLLLightController.h
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLLightController : NSObject

- (id)initWithLight:(NSManagedObject *)light;

@property (nonatomic, readonly) NSManagedObject *light;

@end
