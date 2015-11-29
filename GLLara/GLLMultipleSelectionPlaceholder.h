//
//  GLLMultipleSelectionPlaceholder.h
//  GLLara
//
//  Created by Torsten Kammer on 23.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLSelection;

/*!
 * Class that handles a selection of a property on one or more objects, handling placeholders for empty or no selection.
 *
 * The main difference between this and using NSArrayController is that it updates its value only on request, and this request is done in response to specific UI changes. This avoids the whole key value observing overhead, which can become incredibly large for sufficiently complex situations.
 */
@interface GLLMultipleSelectionPlaceholder : NSObject

- (instancetype)initWithSelection:(GLLSelection *)selection typeKey:(NSString *)selectionTypeKey;

/*! Must be implemented in subclasses: Get the value from a given object, which will be part of the underlying selection. */
- (id)valueFrom:(id)sourceObject;

/*! Must be implemented in subclasses: Set the new value on a given object, which is part of the underlying selection. */
- (void)setValue:(id)value onSourceObject:(id)object;

/*!
 * The value stored here. Observable. Will return multiple selection makrers or empty selection markers as necessary.
 */
@property (nonatomic, retain) id value;

/*! The multiple selection marker returned for value. Defaults to NSMultipleSelectionMarker. */
@property (nonatomic, retain) id multipleSelectionMarker;

/*! The empty selection marker returned for value. Defaults to NSMultipleSelectionMarker. */
@property (nonatomic, retain) id emptySelectionMarker;

/*!
 * Updates the value, firing the appropriate change notifications.
 */
- (void)update;

@end
