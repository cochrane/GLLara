//
//  GLLOptionalPartViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "GLLOptionalPartViewController.h"

#import "GLLItem.h"
#import "GLLItemMesh.h"
#import "GLLModelMesh.h"
#import "GLLOptionalPart.h"

@implementation GLLOptionalPartViewController

- (id)init
{
    self = [super initWithNibName:@"GLLOptionalPartView" bundle:nil];
    if (!self)
        return nil;
    
    _parts = [NSArray array];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

- (void)setRepresentedObject:(id)representedObject {
    NSMutableArray<GLLOptionalPart *> *topLevelParts = [NSMutableArray array];
    if (representedObject) {
        GLLItem *representedItem = [representedObject valueForKey:@"item"];
        for (GLLItemMesh *mesh in representedItem.meshes) {
            NSArray<NSString*> *names = mesh.mesh.optionalPartNames;
            if (names.count == 0)
                continue;
            
            BOOL existsAlready = NO;
            
            // Find parent
            GLLOptionalPart *parent = nil;
            if (names.count > 1) {
                // Find root
                NSString *parentName = names[0];
                for (GLLOptionalPart *part in topLevelParts) {
                    if ([part.name isEqualToString:parentName]) {
                        parent = part;
                        break;
                    }
                }
                if (!parent) {
                    parent = [[GLLOptionalPart alloc] initWithItem:representedItem name:names[0] parent:nil];
                }
                
                // Find rest of path
                for (NSUInteger i = 1; i < names.count - 1; i++) {
                    GLLOptionalPart *newParent = [parent childWithName:names[i]];
                    if (!newParent) {
                        newParent = [[GLLOptionalPart alloc] initWithItem:representedItem name:names[i] parent:parent];
                    }
                    parent = newParent;
                }
                // Check whether we already have this element
                if ([parent childWithName:names[names.count - 1]]) {
                    existsAlready = YES;
                }
            } else {
                for (GLLOptionalPart *part in topLevelParts) {
                    if ([part.name isEqualToString:names[0]]) {
                        existsAlready = YES;
                        break;
                    }
                }
            }
            if (existsAlready)
                continue;
            
            
            // Create and insert part
            GLLOptionalPart *part = [[GLLOptionalPart alloc] initWithItem:representedItem name:names[names.count - 1] parent:parent];
            if (parent == nil) {
                [topLevelParts addObject:part];
            }
        }
    }
    self.parts = topLevelParts;
    
    [super setRepresentedObject:representedObject];
}

@end
