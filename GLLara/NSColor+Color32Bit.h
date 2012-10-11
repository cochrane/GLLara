//
//  NSColor+Color32Bit.h
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>

@interface NSColor (Color32Bit)

- (void)get32BitRGBAComponents:(uint8_t *)components;
- (void)get128BitRGBAComponents:(float *)components;

@end
