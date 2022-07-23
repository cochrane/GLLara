//
//  GLLColorRenderParameterView.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa

/*!
 * @abstract View to set values for a color render paramter.
 * @discussion This class only contains a few outlets, to get access to the
 * subviews in a view-based table view.
 */
@objc class GLLColorRenderParameterView: NSView {
    @IBOutlet var parameterTitle: NSTextField? = nil
    @IBOutlet var parameterDescription: NSTextField? = nil
    @IBOutlet var parameterValue: NSColorWell? = nil
}
