//
//  GLLOptionalPartViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

import Cocoa

@objc class GLLOptionalPartViewController : NSViewController {
    init() {
        super.init(nibName:"GLLOptionalPartView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet var tableView: NSTableView?
    @objc dynamic var parts: [GLLOptionalPart] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Fill list with stuff
        // Meaning set up observing of the GLLSelection (which needs to be passed in
        // as a parameter here), and when it changes and it contains one item
        // (otherwise empty):
        // - Get all the names of optional items. I think that's just from the
        //   initial +/- to the first "."
        // - That list is now what we show. For column 0, show all/none/some, for
        //   column 1 just show the name.
        // - handle clicks on column 0 correctly. Column 1 is not editable.
    }
    
    override var representedObject: Any? {
        didSet {
            guard let representedObject, let representedItem = (representedObject as! NSObject).value(forKeyPath: "item") as? GLLItem else {
                return
            }
            
            var topLevelParts: [GLLOptionalPart] = []
                
            for mesh in representedItem.meshes {
                let names = (mesh as! GLLItemMesh).mesh.optionalPartNames
                if names.count == 0 {
                    continue
                }
                
                var existsAlready = false
                    
                // Find parent
                var parent: GLLOptionalPart? = nil
                if names.count > 1 {
                    // Find root
                    let parentName = names[0];
                    for part in topLevelParts {
                        if part.name == parentName {
                            parent = part
                            break
                        }
                    }
                    if parent == nil {
                        parent = GLLOptionalPart(item: representedItem, name: names[0], parent: nil)
                        topLevelParts.append(parent!)
                    }
                    
                    // Find rest of path
                    for i in 1 ..< names.count - 1 {
                        let newParent = parent?.child(withName: names[i])
                        if newParent == nil {
                            parent = GLLOptionalPart(item: representedItem, name: names[0], parent: nil)
                        }
                        parent = newParent
                    }
                    // Check whether we already have this element
                    if parent!.child(withName: names.last!) != nil {
                        existsAlready = true
                    }
                } else {
                    existsAlready = topLevelParts.contains(where: { $0.name == names[0] })
                }
                if existsAlready {
                    continue
                }
                
                // Create and insert part
                let part = GLLOptionalPart(item: representedItem, name: names.last!, parent: parent)
                if parent == nil {
                    topLevelParts.append(part)
                }
            }
            
            parts = topLevelParts
        }
    }
    
}
