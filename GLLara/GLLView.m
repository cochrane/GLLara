//
//  GLLView.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLView.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "GLLCamera.h"
#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLItemDragDestination.h"
#import "GLLResourceManager.h"
#import "GLLPreferenceKeys.h"
#import "GLLSelection.h"
#import "GLLTexture.h"
#import "NSCharacterSet+SetOperations.h"
#import "simd_matrix.h"
#import "simd_project.h"
#import "GLLTiming.h"

#include "GLLara-Swift.h"

static NSCharacterSet *wasdCharacters;
static NSCharacterSet *xyzCharacters;
static NSCharacterSet *arrowCharacters;
static NSMutableCharacterSet *interestingCharacters;

@interface GLLView ()
{
    BOOL inGesture;
    BOOL shiftIsDown;
    BOOL altIsDown;
    
    NSMutableCharacterSet *keysDown;
    
    id textureChangeObserver;
    id settingsChangeObserver;
    
    BOOL didHaveMultisample;
    NSInteger currentNumberOfSamples;
    
    GLLItemDragDestination *dragDestination;
}

- (void)_processEventsStartingWith:(NSEvent *)theEvent;
- (GLLItemBone *)closestBoneAtScreenPoint:(NSPoint)point fromBones:(id)bones;
- (void)_updateFromUserSettings;

@end

const double unitsPerSecond = 0.2;

@implementation GLLView

+ (void)initialize
{
    wasdCharacters = [NSCharacterSet characterSetWithCharactersInString:@"wasd"];
    xyzCharacters = [NSCharacterSet characterSetWithCharactersInString:@"xyz"];
    arrowCharacters = [NSCharacterSet characterSetWithRange:NSMakeRange(NSUpArrowFunctionKey, 4)];
    interestingCharacters = [NSMutableCharacterSet characterSetWithCharactersInString:@"wasdxyz"];
    [interestingCharacters addCharactersInRange:NSMakeRange(NSUpArrowFunctionKey, 4)];
}

- (id)initWithFrame:(NSRect)frame
{
    // Not calling initWithFrame:pixelFormat:, because we set up our own context.
    if (!(self = [super initWithFrame:frame])) return nil;
    
    didHaveMultisample = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefUseMSAA];
    currentNumberOfSamples = [[NSUserDefaults standardUserDefaults] integerForKey:GLLPrefMSAAAmount];
    
    self.device = MTLCreateSystemDefaultDevice();
    self.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);
    self.enableSetNeedsDisplay = NO;
    self.paused = NO;
    self.autoResizeDrawable = YES;
    
    // Event handling
    keysDown = [[NSMutableCharacterSet alloc] init];
    
    __weak GLLView *weakSelf = self;
    textureChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GLLTextureChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
        dispatch_async(dispatch_get_main_queue(), ^(){
            //weakSelf.needsDisplay = YES;
        });
    }];
    settingsChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
        dispatch_async(dispatch_get_main_queue(), ^(){
            [weakSelf _updateFromUserSettings];
        });
    }];
    
    self.showSelection = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefShowSkeleton];
    
    [self registerForDraggedTypes:@[ UTTypeFileURL.identifier ]];
    dragDestination = [[GLLItemDragDestination alloc] init];
    
    return self;
};

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:textureChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:settingsChangeObserver];
}

- (void)unload
{
    _viewDrawer = nil;
    _camera = nil;
}

- (void)setCamera:(GLLCamera *)camera sceneDrawer:(GLLSceneDrawer *)sceneDrawer;
{
    _camera = camera;
    _sceneDrawer = sceneDrawer;
    
    _viewDrawer = [[GLLViewDrawer alloc] initWithSceneDrawer:sceneDrawer camera:camera view: self];
}

- (void)rotateWithEvent:(NSEvent *)event
{
    if (self.camera.cameraLocked) return;
    
    float angle = event.rotation * M_PI / 180.0;
    self.camera.longitude -= angle;
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    if (self.camera.cameraLocked) return;
    
    self.camera.distance *= 1 + event.magnification;
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
    inGesture = YES;
    [self.camera.managedObjectContext.undoManager beginUndoGrouping];
    self.camera.managedObjectContext.undoManager.actionIsDiscardable = YES;
}
- (void)endGestureWithEvent:(NSEvent *)event
{
    inGesture = NO;
    [self.camera.managedObjectContext.undoManager setActionName:NSLocalizedString(@"Camera changed", @"Undo: data of camera has changed.")];
    [self.camera.managedObjectContext.undoManager endUndoGrouping];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    if (self.camera.cameraLocked) return;
    
    self.camera.currentPositionX += theEvent.deltaX / self.bounds.size.width;
    self.camera.currentPositionZ += theEvent.deltaY / self.bounds.size.height;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([xyzCharacters hasIntersectionWithSet:keysDown])
    {
        CGFloat amountX = theEvent.deltaX / self.bounds.size.width;
        CGFloat amountY = theEvent.deltaY / self.bounds.size.height;
        
        CGFloat angle = amountX + amountY;
        
        for (GLLItemBone *bone in [self.document.selection valueForKey:@"selectedBones"])
        {
            if ([keysDown characterIsMember:'x']) bone.rotationX += angle;
            if ([keysDown characterIsMember:'y']) bone.rotationY += angle;
            if ([keysDown characterIsMember:'z']) bone.rotationZ += angle;
        }
    }
    else if (theEvent.modifierFlags & NSEventModifierFlagOption)
    {
        // Move the object in the x/z plane
        CGFloat factor = (theEvent.modifierFlags & NSEventModifierFlagShift) ? 0.01f : 0.001f;
        vec_float4 delta = simd_make(theEvent.deltaX * factor, 0.0f, theEvent.deltaY * factor, 0.0f);
        delta = simd_mat_vecunrotate(self.camera.viewMatrix, delta);
        
        for (GLLItem *item in [self.document.selection valueForKey:@"selectedItems"])
        {
            item.positionX += simd_extract(delta, 0);
            item.positionZ += simd_extract(delta, 2);
        }
        
        //self.needsDisplay = YES;
    }
    else if (theEvent.modifierFlags & NSEventModifierFlagShift && ![wasdCharacters hasIntersectionWithSet:keysDown])
    {
        // This is a move event
        if (self.camera.cameraLocked) return;
        float deltaX = -theEvent.deltaX / self.bounds.size.width;
        float deltaY = theEvent.deltaY / self.bounds.size.height;
        
        [self.camera moveLocalX:deltaX y:deltaY z:0.0f];
    }
    else if (theEvent.modifierFlags & NSEventModifierFlagControl)
    {
        [self rightMouseDragged:theEvent];
    }
    else
    {
        // This is a rotate event
        if (self.camera.cameraLocked) return;
        self.camera.longitude -= theEvent.deltaX * M_PI / self.bounds.size.width;
        self.camera.latitude -= theEvent.deltaY * M_PI / self.bounds.size.height;
    }
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
    if (self.camera.cameraLocked) return;
    
    CGFloat deltaX = theEvent.deltaX * M_PI / self.bounds.size.width;
    CGFloat deltaY = theEvent.deltaY * M_PI / self.bounds.size.height;
    
    // Turn camera around it's current position. To do this:
    // 1. Find current position
    vec_float4 position = self.camera.cameraWorldPosition;
    // 2. Calculate new position of target
    float cameraRelativeLatitude = self.camera.latitude;
    float cameraRelativeLongitude = self.camera.longitude;
    
    cameraRelativeLongitude -= deltaX;
    cameraRelativeLatitude -= deltaY;
    
    vec_float4 viewDirection = simd_mul(simd_mat_euler(simd_make(cameraRelativeLatitude, cameraRelativeLongitude, 0.0f, 0.0f), simd_e_w), simd_e_z);
    
    vec_float4 newTargetPosition = position - viewDirection * simd_splatf(self.camera.distance);
    self.camera.positionX = simd_extract(newTargetPosition, 0);
    self.camera.positionY = simd_extract(newTargetPosition, 1);
    self.camera.positionZ = simd_extract(newTargetPosition, 2);
    
    // 3. Calculate new rotation of camera
    self.camera.longitude -= deltaX;
    self.camera.latitude -= deltaY;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent;
{
    [self _processEventsStartingWith:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (self.showSelection) {
        // Try to find the bone that corresponds to this event.
        GLLItemBone *bone = [self closestBoneAtScreenPoint:[self convertPoint:theEvent.locationInWindow fromView:nil] fromBones:self.document.allBones];
        
        if (bone)
        {
            NSMutableArray *selectedBones = [self.document.selection mutableArrayValueForKey:@"selectedBones"];
            // Set it as selected
            if (theEvent.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagShift))
            {
                // Add to the selection
                NSUInteger index = [selectedBones indexOfObject:bone];
                if (index == NSNotFound)
                    [selectedBones addObject:bone];
                else
                    [selectedBones removeObjectAtIndex:index];
            }
            else
            {
                // Remove all other selection
                NSMutableArray *selectedObjects = [self.document.selection mutableArrayValueForKey:@"selectedObjects"];
                [selectedObjects removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedObjects.count)]];
                
                // Set self as only selection
                [selectedBones addObject:bone];
            }
        }
    }
    
    // Next (in either case): Start mouse movement
    if (self.camera.cameraLocked) return;
    [self _processEventsStartingWith:theEvent];
}

#pragma mark - Drag and drop

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSWindowController *windowController = self.window.windowController;
    dragDestination.document = windowController.document;
    
    return [dragDestination itemDraggingEntered:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSWindowController *windowController = self.window.windowController;
    dragDestination.document = windowController.document;
    
    NSError *error = nil;
    BOOL success = [dragDestination performItemDragOperation:sender error:&error];
    if (!success && error)
        [self presentError:error];
    return success;
}

#pragma mark - Private methods

- (void)_updateFromUserSettings {
    //BOOL usingMSAA = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefUseMSAA];
    //NSInteger numberOfSamples = [[NSUserDefaults standardUserDefaults] integerForKey:GLLPrefMSAAAmount];
    
    //NSInteger usedNumberOfSamples = usingMSAA ? numberOfSamples : 1;
    
    self.sampleCount = 1;//usedNumberOfSamples;
    
    self.showSelection = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefShowSkeleton];
}

- (void)_processEventsStartingWith:(NSEvent *)theEvent;
{
    NSTimeInterval lastEvent = [NSDate timeIntervalSinceReferenceDate];
    
    [NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:1.0 / 30.0];
    
    while(YES)
    {
        NSTimeInterval rightNow = [NSDate timeIntervalSinceReferenceDate];
        double diff = rightNow - lastEvent;
        lastEvent = rightNow;
        
        if (shiftIsDown) diff *= 10.0f;
        
        switch (theEvent.type)
        {
            case NSEventTypeAppKitDefined:
                if (theEvent.subtype == NSEventSubtypeApplicationDeactivated)
                {
                    [NSEvent stopPeriodicEvents];
                    //self.needsDisplay = YES;
                    return;
                }
                break;
            case NSEventTypeKeyDown:
            {
                [keysDown addCharactersInString:[theEvent.charactersIgnoringModifiers lowercaseString]];
                shiftIsDown = (theEvent.modifierFlags & NSEventModifierFlagShift) != 0;
                altIsDown = (theEvent.modifierFlags & NSEventModifierFlagOption) != 0;
            }
                break;
            case NSEventTypeKeyUp:
            {
                [keysDown removeCharactersInString:[theEvent.charactersIgnoringModifiers lowercaseString]];
                shiftIsDown = (theEvent.modifierFlags & NSEventModifierFlagShift) != 0;
                altIsDown = (theEvent.modifierFlags & NSEventModifierFlagOption) != 0;
            }
                break;
            case NSEventTypeFlagsChanged:
                shiftIsDown = (theEvent.modifierFlags & NSEventModifierFlagShift) != 0;
                break;
            case NSEventTypeScrollWheel:
                [self scrollWheel:theEvent];
                break;
            case NSEventTypeLeftMouseDragged:
                [self mouseDragged:theEvent];
                break;
            case NSEventTypeRightMouseDragged:
                [self rightMouseDragged:theEvent];
                break;
            default:
                break;
        }
        if (![interestingCharacters hasIntersectionWithSet:keysDown] && !shiftIsDown && !altIsDown) break;
        
        // Perform actions
        // - Move
        if (!self.camera.cameraLocked)
        {
            float deltaX = 0, deltaY = 0, deltaZ = 0;
            if ([keysDown characterIsMember:'a'] && ![keysDown characterIsMember:'d']) deltaX = -diff * unitsPerSecond;
            else if (![keysDown characterIsMember:'a'] && [keysDown characterIsMember:'d']) deltaX = diff * unitsPerSecond;
            if ([keysDown characterIsMember:'w'] && ![keysDown characterIsMember:'s']) deltaZ = -diff * unitsPerSecond;
            else if (![keysDown characterIsMember:'w'] && [keysDown characterIsMember:'s']) deltaZ = diff * unitsPerSecond;
            [self.camera moveLocalX:deltaX y:deltaY z:deltaZ];
        }
        
        // Move bones with arrow keys
        if ([xyzCharacters hasIntersectionWithSet:keysDown])
        {
            CGFloat delta = 0.0f;
            if (([keysDown characterIsMember:NSLeftArrowFunctionKey] || [keysDown characterIsMember:NSUpArrowFunctionKey]) && !([keysDown characterIsMember:NSRightArrowFunctionKey] || [keysDown characterIsMember:NSDownArrowFunctionKey]))
                delta = unitsPerSecond * diff * 0.1;
            else if (!([keysDown characterIsMember:NSLeftArrowFunctionKey] || [keysDown characterIsMember:NSUpArrowFunctionKey]) && ([keysDown characterIsMember:NSRightArrowFunctionKey] || [keysDown characterIsMember:NSDownArrowFunctionKey]))
                delta = unitsPerSecond * diff * -0.1;
            
            for (GLLItemBone *bone in [self.document.selection valueForKey:@"selectedBones"])
            {
                if ([keysDown characterIsMember:'x']) bone.positionX += delta;
                if ([keysDown characterIsMember:'y']) bone.positionY += delta;
                if ([keysDown characterIsMember:'z']) bone.positionZ += delta;
            }
        }
        else if (theEvent.modifierFlags & NSEventModifierFlagOption)
        {
            // Move the object up or down with arrow keys
            CGFloat deltaY = 0;
            if ([keysDown characterIsMember:NSUpArrowFunctionKey] && ![keysDown characterIsMember:NSDownArrowFunctionKey]) deltaY = diff * unitsPerSecond;
            else if (![keysDown characterIsMember:NSUpArrowFunctionKey] && [keysDown characterIsMember:NSDownArrowFunctionKey]) deltaY = -diff * unitsPerSecond;
            
            for (GLLItem *item in [self.document.selection valueForKey:@"selectedItems"])
                item.positionY += deltaY * 0.1;
            
        }
        else if ([arrowCharacters hasIntersectionWithSet:keysDown])
        {
            // Move object in x/z plane with arrow keys
            CGFloat deltaX = 0, deltaZ = 0;
            if ([keysDown characterIsMember:NSLeftArrowFunctionKey] && ![keysDown characterIsMember:NSRightArrowFunctionKey]) deltaX = -diff * unitsPerSecond;
            else if (![keysDown characterIsMember:NSLeftArrowFunctionKey] && [keysDown characterIsMember:NSRightArrowFunctionKey]) deltaX = diff * unitsPerSecond;
            if ([keysDown characterIsMember:NSUpArrowFunctionKey] && ![keysDown characterIsMember:NSDownArrowFunctionKey]) deltaZ = -diff * unitsPerSecond;
            else if (![keysDown characterIsMember:NSUpArrowFunctionKey] && [keysDown characterIsMember:NSDownArrowFunctionKey]) deltaZ = diff * unitsPerSecond;
            
            vec_float4 delta = simd_make(deltaX * 0.1, 0.0f, deltaZ * 0.1, 0.0f);
            delta = simd_mat_vecunrotate(self.camera.viewMatrix, delta);
            
            for (GLLItem *item in [self.document.selection valueForKey:@"selectedItems"])
            {
                item.positionX += simd_extract(delta, 0);
                item.positionZ += simd_extract(delta, 2);
            }
        }
        
        // - Prepare for next move through the loop
        //self.needsDisplay = YES;
        
        theEvent = [self.window nextEventMatchingMask:NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskRightMouseDragged | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged |NSEventMaskFlagsChanged | NSEventMaskScrollWheel | NSEventMaskPeriodic | NSEventTypeAppKitDefined untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];
    }
    [NSEvent stopPeriodicEvents];
    
    //self.needsDisplay = YES;
}

- (GLLItemBone *)closestBoneAtScreenPoint:(NSPoint)point fromBones:(id)bones;
{
    // All calculations are in screen coordinates, so all values are points
    
    mat_float16 viewProjection = self.camera.viewProjectionMatrix;
    
    float closestDistance = HUGE_VALF;
    GLLItemBone *closestBone = nil;
    
    float width = self.bounds.size.width;
    float height = self.bounds.size.height;
    
    for (GLLItemBone *bone in bones)
    {
        vec_float4 position = bone.globalPosition;
        vec_float4 screenPosition = simd_mul(viewProjection, position);
        screenPosition /= simd_splat(screenPosition, 3);
        
        float screenX = (simd_extract(screenPosition, 0) * 0.5 + 0.5) * width;
        float screenY = (simd_extract(screenPosition, 1) * 0.5 + 0.5) * height;
        
        float distanceToRay = sqrtf((screenX - point.x)*(screenX - point.x) + (screenY - point.y) *(screenY - point.y));
        
        if (distanceToRay > 10.0f) continue;
        
        float zDistance = simd_extract(screenPosition, 2);
        if (zDistance < closestDistance)
        {
            closestDistance = zDistance;
            closestBone = bone;
        }
    }
    
    return closestBone;
}

@end
