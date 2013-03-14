//
//  GLLRenderWindow.h
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GLLView.h"

/* This class handles only scripting stuff */

@interface GLLRenderWindow : NSWindow

@property (nonatomic, unsafe_unretained) IBOutlet GLLView *renderView;

@property (nonatomic, readonly) GLLCamera *camera;

@property (nonatomic) BOOL scriptingLocked;
@property (nonatomic) CGFloat scriptingHeight;
@property (nonatomic) CGFloat scriptingWidth;

@end
