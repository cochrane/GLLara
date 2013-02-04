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

/*!
 * @abstract UI values for a model-specific uniform variable.
 * @discussion This class contains everything to build a UI for a model-specific
 * variable, allowing end-users to adjust it on the fly. This includes localized
 * descriptions, type information and, for sliders, minimum and maximum settings.
 */
@interface GLLRenderParameterDescription : NSObject

- (id)initWithPlist:(NSDictionary *)plist;

@property (nonatomic, readonly) float min;
@property (nonatomic, readonly) float max;
@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSString *localizedDescription;

@property (nonatomic, readonly) NSString *type;

@end
