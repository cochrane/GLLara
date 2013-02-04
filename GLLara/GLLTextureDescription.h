//
//  GLLTextureDescription.h
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLLTextureDescription : NSObject

- (id)initWithPlist:(NSDictionary *)plist;

@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSString *localizedDescription;


@end
