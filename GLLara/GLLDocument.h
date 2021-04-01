//
//  GLLDocument.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSPersistentDocument.h>
#import <Foundation/Foundation.h>

@class GLLItem;
@class GLLItemBone;
@class GLLModel;
@class GLLView;
@class GLLSourceListController;
@class GLLSelection;

/*!
 * @abstract The main class for a scene.
 * @discussion This class is actually mostly empty. Core Data takes care of just about anything. The main jobs are replying to messages that might come from the menu or from buttons in the UI, and setting up the default objects (right now: Three directional lights, an ambient light and a single camera.)
 * It also sets up the view controllers.
 */
@interface GLLDocument : NSPersistentDocument

- (GLLItem *)addModelAtURL:(NSURL *)url error:(NSError *__autoreleasing*)error;
- (GLLItem *)addModel:(GLLModel *)model;
- (GLLItem *)addImagePlane:(NSURL *)url error:(NSError *__autoreleasing*)error;

- (IBAction)openNewRenderView:(id)sender;
- (IBAction)loadMesh:(id)sender;

- (IBAction)delete:(id)sender;
- (IBAction)exportSelectedModel:(id)sender;
- (IBAction)exportSelectedPose:(id)sender;
- (IBAction)exportItem:(id)sender;
- (IBAction)revealModelInFinder:(id)sender;

@property (nonatomic, readonly) GLLSourceListController *sourceListController;
@property (nonatomic, readonly) GLLSelection *selection;
@property (nonatomic, readonly) NSArray<GLLItemBone *> *allBones;

- (void)notifyTexturesNotLoaded:(NSDictionary<NSURL*,NSError*>*)textures;

@end
