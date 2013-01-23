//
//  GLLView.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLView.h"

#import <AppKit/NSWindow.h>
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "GLLCamera.h"
#import "GLLDocument.h"
#import "GLLResourceManager.h"
#import "GLLSceneDrawer.h"
#import "GLLSelection.h"
#import "GLLItemBone.h"
#import "GLLViewDrawer.h"
#import "simd_matrix.h"
#import "simd_project.h"

@interface GLLView ()
{
	BOOL inGesture;
	BOOL shiftIsDown;
	BOOL inWASDMove;
}

- (void)_processEventsStartingWith:(NSEvent *)theEvent;
- (GLLItemBone *)closestBoneAtScreenPoint:(NSPoint)point fromBones:(id)bones;

@end

const double unitsPerSecond = 0.2;

@implementation GLLView

- (id)initWithFrame:(NSRect)frame
{
	// Not calling initWithFrame:pixelFormat:, because we set up our own context.
	if (!(self = [super initWithFrame:frame])) return nil;
	
	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		NSOpenGLPFAMultisample, 1,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, 4,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFAColorSize, 24,
		0
	};
	
	NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:format shareContext:[[GLLResourceManager sharedResourceManager] openGLContext]];
	[self setPixelFormat:format];
	[self setOpenGLContext:context];
	[context setView:self];
	[self setWantsBestResolutionOpenGLSurface:YES];
	
	return self;
};

- (void)unload
{
	[self.openGLContext makeCurrentContext];
	_viewDrawer = nil;
	_camera = nil;
}

- (void)setCamera:(GLLCamera *)camera sceneDrawer:(GLLSceneDrawer *)sceneDrawer;
{
	_camera = camera;
	_sceneDrawer = sceneDrawer;
	
	_viewDrawer = [[GLLViewDrawer alloc] initWithManagedSceneDrawer:sceneDrawer camera:camera context:self.openGLContext pixelFormat:self.pixelFormat];
	_viewDrawer.view = self;
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
	[self.camera.managedObjectContext.undoManager setActionIsDiscardable:YES];
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
	if (self.camera.cameraLocked) return;
	
	if (theEvent.modifierFlags & NSShiftKeyMask && !inWASDMove)
	{
		// This is a move event
		float deltaX = -theEvent.deltaX / self.bounds.size.width;
		float deltaY = theEvent.deltaY / self.bounds.size.height;
		
		[self.camera moveLocalX:deltaX y:deltaY z:0.0f];
	}
	else
	{
		// This is a rotate event
		self.camera.longitude -= theEvent.deltaX * M_PI / self.bounds.size.width;
		self.camera.latitude -= theEvent.deltaY * M_PI / self.bounds.size.height;
	}
}

- (void)reshape
{
	[self.openGLContext makeCurrentContext];
	
	// Set height and width for camera.
	// Note: This is points, not pixels.
	self.camera.actualWindowWidth = self.bounds.size.width;
	self.camera.actualWindowHeight = self.bounds.size.height;
	
	// Pixels are used for glViewport exclusively.
	NSRect actualPixels = [self convertRectToBacking:[self bounds]];
	glViewport(0, 0, actualPixels.size.width, actualPixels.size.height);
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self.viewDrawer drawShowingSelection:YES];
	[self.openGLContext flushBuffer];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent;
{
	if (self.camera.cameraLocked) return;
	[self _processEventsStartingWith:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	// Try to find the bone that corresponds to this event.
	GLLItemBone *bone = [self closestBoneAtScreenPoint:[self convertPoint:theEvent.locationInWindow fromView:nil] fromBones:self.document.allBones];
	
	if (bone)
	{
		NSMutableArray *selectedBones = [self.document.selection mutableArrayValueForKey:@"selectedBones"];
		// Set it as selected
		if (theEvent.modifierFlags & (NSCommandKeyMask | NSShiftKeyMask))
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
			// Set as only selection
			[selectedBones replaceObjectsInRange:NSMakeRange(0, selectedBones.count) withObjectsFromArray:@[ bone ]];
		}
	}
	
	// Next (in either case): Start mouse movement
	if (self.camera.cameraLocked) return;
	[self _processEventsStartingWith:theEvent];
}

#pragma mark - Private methods

- (void)_processEventsStartingWith:(NSEvent *)theEvent;
{
	if (self.camera.cameraLocked) return;
	
	BOOL wDown = NO;
	BOOL aDown = NO;
	BOOL sDown = NO;
	BOOL dDown = NO;
	BOOL mouseDown = NO;
	
	NSTimeInterval lastEvent = [NSDate timeIntervalSinceReferenceDate];
	
	//GLLItemBone *lastSelectedBone = nil;
	
	[NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:1.0 / 30.0];
	
	while(YES)
	{
		NSTimeInterval rightNow = [NSDate timeIntervalSinceReferenceDate];
		double diff = rightNow - lastEvent;
		lastEvent = rightNow;
		
		if (shiftIsDown) diff *= 10.0f;
		
		switch (theEvent.type)
		{
			case NSAppKitDefined:
				if (theEvent.subtype == NSApplicationDeactivatedEventType)
				{
					[NSEvent stopPeriodicEvents];
					self.needsDisplay = YES;
					return;
				}
				break;
			case NSKeyDown:
			{
				unichar firstCharacter = tolower([theEvent.charactersIgnoringModifiers characterAtIndex:0]);
				wDown = wDown || (firstCharacter == 'w');
				aDown = aDown || (firstCharacter == 'a');
				sDown = sDown || (firstCharacter == 's');
				dDown = dDown || (firstCharacter == 'd');
				shiftIsDown = (theEvent.modifierFlags & NSShiftKeyMask) != 0;
			}
				break;
			case NSKeyUp:
			{
				unichar firstCharacter = tolower([theEvent.charactersIgnoringModifiers characterAtIndex:0]);
				wDown = wDown && (firstCharacter != 'w');
				aDown = aDown && (firstCharacter != 'a');
				sDown = sDown && (firstCharacter != 's');
				dDown = dDown && (firstCharacter != 'd');
				shiftIsDown = (theEvent.modifierFlags & NSShiftKeyMask) != 0;
			}
				break;
			case NSFlagsChanged:
				shiftIsDown = (theEvent.modifierFlags & NSShiftKeyMask) != 0;
				break;
			case NSScrollWheel:
				[self scrollWheel:theEvent];
				break;
			case NSLeftMouseDragged:
				[self mouseDragged:theEvent];
				break;
			case NSLeftMouseUp:
				mouseDown = NO;
				break;
			case NSLeftMouseDown:
				mouseDown = YES;
				break;
		}
		if (!wDown && !aDown && !sDown && !dDown && !mouseDown && !shiftIsDown) break;
		inWASDMove = wDown || aDown || sDown || dDown;
		
		// Perform actions
		float deltaX = 0, deltaY = 0, deltaZ = 0;
		if (aDown && !dDown) deltaX = -diff * unitsPerSecond;
		else if (!aDown & dDown) deltaX = diff * unitsPerSecond;
		if (wDown && !sDown) deltaZ = -diff * unitsPerSecond;
		else if (!wDown && sDown) deltaZ = diff * unitsPerSecond;
		
		[self.camera moveLocalX:deltaX y:deltaY z:deltaZ];
		
		// Prepare for next move through the loop
		self.needsDisplay = YES;
		
		theEvent = [self.window nextEventMatchingMask:NSKeyDownMask | NSKeyUpMask | NSRightMouseDraggedMask | NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask | NSScrollWheelMask | NSPeriodicMask | NSApplicationDeactivatedEventType untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];
	}
	[NSEvent stopPeriodicEvents];
	inWASDMove = NO;
	
	self.needsDisplay = YES;
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
		vec_float4 position;
		[bone.globalPosition getValue:&position];
		vec_float4 screenPosition = simd_mat_vecmul(viewProjection, position);
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
