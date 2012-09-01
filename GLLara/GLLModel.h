//
//  GLLModel.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLLModel : NSObject

- (id)initWithData:(NSData *)data;

@property (nonatomic, assign, readonly) BOOL hasBones;

@property (nonatomic, copy, readonly) NSArray *bones;
@property (nonatomic, copy, readonly) NSArray *meshes;

@end
