//
//  GLLBoneTransformViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 * @abstract View controller for a bone.
 * @discussion As you can see, it's mostly empty, but it does reset the bones of an object.
 */
@class GLLBoneTransformation;

@interface GLLBoneTransformViewController : NSViewController

- (IBAction)resetAllValues:(id)sender;

@end
