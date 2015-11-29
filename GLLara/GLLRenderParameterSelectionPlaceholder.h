//
//  GLLRenderParameterSelectionPlaceholder.h
//  GLLara
//
//  Created by Torsten Kammer on 29.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLMultipleSelectionPlaceholder.h"

@interface GLLRenderParameterSelectionPlaceholder : GLLMultipleSelectionPlaceholder

- (instancetype)initWithParameterNameName:(NSString *)parameterName keyPath:(NSString *)keyPath selection:(GLLSelection *)selection;

@end
