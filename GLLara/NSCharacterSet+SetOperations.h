//
//  NSCharacterSet+SetOperations.h
//  GLLara
//
//  Created by Torsten Kammer on 24.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (SetOperations)

- (BOOL)hasIntersectionWithSet:(NSCharacterSet *)other;

@end
