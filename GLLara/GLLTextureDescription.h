//
//  GLLTextureDescription.h
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @abstract UI values for a texture.
 * @discussion This class contains everything to build a UI for a texture,
 * allowing end-users to adjust it on the fly. So far, this means only a localized
 * description.
 */
@interface GLLTextureDescription : NSObject

- (id)initWithPlist:(NSDictionary *)plist;

@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSString *localizedDescription;


@end
