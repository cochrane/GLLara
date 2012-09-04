//
//  GLLShaderList.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLLShaderList : NSObject

+ (id)defaultShaderList;

- (id)initWithPlist:(NSDictionary *)propertyList;

@property (nonatomic, copy, readonly) NSArray *shaderNames;
- (NSString *)vertexShaderForName:(NSString *)shaderName;
- (NSString *)geometryShaderForName:(NSString *)shaderName;
- (NSString *)fragmentShaderForName:(NSString *)shaderName;
- (NSArray *)renderParameterNamesForName:(NSString *)shaderName;

@end
