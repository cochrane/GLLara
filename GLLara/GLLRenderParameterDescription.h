//
//  GLLRenderParameterDescription.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *GLLRenderParameterTypeFloat;
extern NSString *GLLRenderParameterTypeColor;

@interface GLLRenderParameterDescription : NSObject

- (id)initWithPlist:(NSDictionary *)plist;

@property (nonatomic, readonly) float min;
@property (nonatomic, readonly) float max;
@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSString *localizedDescription;

@property (nonatomic, readonly) NSString *type;

@end
