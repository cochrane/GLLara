//
//  GLLMeshSplitter.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLLMeshSplitter : NSObject

- (id)initWithPlist:(NSDictionary *)plist;

@property (nonatomic, assign, readonly) const float *min;
@property (nonatomic, assign, readonly) const float *max;
@property (nonatomic, copy, readonly) NSString *newName;

@end
