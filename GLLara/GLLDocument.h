//
//  GLLDocument.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLView;

/*!
 * @abstract The main class for a scene.
 * @discussion This class is actually mostly empty. Core Data takes care of just about anything. The main jobs are replying to messages that might come from the menu or from buttons in the UI, and setting up the default objects (right now: Three directional lights, an ambient light and a single camera.)
 * It also sets up the view controllers.
 */
@interface GLLDocument : NSPersistentDocument

- (IBAction)openNewRenderView:(id)sender;

@end
