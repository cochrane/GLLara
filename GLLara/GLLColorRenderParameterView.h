//
//  GLLColorRenderParameterView.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @abstract View to set values for a float render paramter.
 * @discussion This class only contains a few outlets, to get access to the
 * subviews in a view-based table view.
 */
@interface GLLColorRenderParameterView : NSView

@property (nonatomic) IBOutlet NSTextField *parameterTitle;
@property (nonatomic) IBOutlet NSTextField *parameterDescription;
@property (nonatomic) IBOutlet NSColorWell *parameterValue;

@end
