//
//  GLLImageView.h
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @abstract Subclass of image view that exposes a read-write binding for
 * the image's URL.
 * @discussion Because for some reaosn valueURL in the normal NSImageView
 * is read-only.
 *
 * The setting for imageURL happens using a custom system, so things like
 * value transformers do not work here.
 */
@interface GLLImageView : NSImageView

@property (nonatomic) NSURL *imageURL;

@end
