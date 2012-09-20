//
//  TRItemSelectWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 18.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TRItemView;
@class TR1Level;

@interface TRItemSelectWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic) TR1Level *level;

@property (nonatomic) IBOutlet NSOutlineView *sourceView;
@property (nonatomic) IBOutlet TRItemView *itemView;

@end
