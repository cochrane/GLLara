//
//  GLLAmbientLight.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*!
 * @abstract A scene's ambient light information.
 * @discussion Each scene will have only one. The index is only for sorting in
 * the UI.
 */
@interface GLLAmbientLight : NSManagedObject

@property (nonatomic, retain) NSColor *color;
@property (nonatomic) NSUInteger index;

@end
