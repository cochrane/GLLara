//
//  GLLCameraTarget.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLCameraTarget.h"
#import "GLLItemBone.h"

#import "GLLItem.h"
#import "simd_functions.h"

static void *contextMarker = (void *) 0xdeadbeef;

@interface GLLCameraTarget ()
{
	BOOL didRegister;
}

@property (nonatomic, assign, readwrite) vec_float4 position;
- (void)_updatePosition;

@end

@implementation GLLCameraTarget

+ (NSSet *)keyPathsForValuesAffectingDisplayName
{
	return [NSSet setWithObjects:@"name", nil];
}

@synthesize position;

@dynamic name;
@dynamic bones;
@dynamic cameras;

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	if (!didRegister)
		[self addObserver:self forKeyPath:@"bones" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:contextMarker];
	didRegister = YES;
}
- (void)awakeFromInsert
{
	[super awakeFromInsert];
	if (!didRegister)
		[self addObserver:self forKeyPath:@"bones" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:contextMarker];
	didRegister = YES;
}
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	if (!didRegister)
		[self addObserver:self forKeyPath:@"bones" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:contextMarker];
	didRegister = YES;
}
- (void)willTurnIntoFault
{
	if (didRegister)
		[self removeObserver:self forKeyPath:@"bones"];
	didRegister = NO;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == contextMarker && [keyPath isEqual:@"bones"])
	{
		if (![change[NSKeyValueChangeOldKey] isKindOfClass:[NSNull class]])
			for (GLLItemBone *transform in change[NSKeyValueChangeOldKey])
				[transform removeObserver:self forKeyPath:@"globalTransform"];
		
		if (![change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
			for (GLLItemBone *transform in change[NSKeyValueChangeNewKey])
				[transform addObserver:self forKeyPath:@"globalTransform" options: NSKeyValueObservingOptionInitial context:contextMarker];
	}
	else if (context == contextMarker && [keyPath isEqual:@"globalTransform"])
	{
		[self _updatePosition];
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSString *)displayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"%@ — %@", @"camera target name format"), self.name, [[self.bones.anyObject item] displayName]];
}

- (void)_updatePosition
{
	vec_float4 newPosition;
	for (GLLItemBone *transform in self.bones)
	{
		vec_float4 transformPosition;
		[transform.globalPosition getValue:&transformPosition];
		newPosition += transformPosition;
	}
	
	[self willChangeValueForKey:@"position"];
	self.position = newPosition / simd_splatf(self.bones.count);
	[self didChangeValueForKey:@"position"];
}

@end
