//
//  GLLColorRenderParameterView.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLColorRenderParameterView : NSView

@property (nonatomic) IBOutlet NSTextField *parameterTitle;
@property (nonatomic) IBOutlet NSTextField *parameterDescription;
@property (nonatomic) IBOutlet NSColorWell *parameterValue;

@end
