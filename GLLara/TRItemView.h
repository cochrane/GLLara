//
//  TRItemView.h
//  GLLara
//
//  Created by Torsten Kammer on 18.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSOpenGLView.h>
#import <Foundation/Foundation.h>

@class TR1Level;
@class TR1Moveable;
@class TR1Room;
@class TR1StaticMesh;

/*!
 * A very simple view to render one type of classic Tomb Raider item
 *
 * This view represents either a moveable item, a static item, a single room or all rooms in a level (without or without the pre-existing moveables). It draws it (for models in a default position with none of the parts rotated, which can look awkward, but it's just for simple representation), allows the user to rotate around it, and that's it.
 *
 * It uses OpenGL 3.2 Core profile, using a shader that is embedded directly into it, because I expect to re-use this view for other occasions and want as few distractions as possible.
 */
@interface TRItemView : NSOpenGLView

- (void)showMoveable:(TR1Moveable *)moveable;
- (void)showRoom:(TR1Room *)room;
- (void)showStaticMesh:(TR1StaticMesh *)staticMesh;
- (void)showAllRoomsOfLevel:(TR1Level *)level withMoveables:(BOOL)includeThem;

@end
