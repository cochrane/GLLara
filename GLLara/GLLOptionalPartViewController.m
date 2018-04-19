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
    NSMutableArray<GLLOptionalPart *> *optionalParts = [NSMutableArray array];
    NSMutableSet<NSString *> *names = [NSMutableSet set];
    if (representedObject) {
        GLLItem *representedItem = [representedObject valueForKey:@"item"];
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"[-+]([^\\.]+)" options:NSRegularExpressionCaseInsensitive error:NULL];
        for (GLLItemMesh *mesh in representedItem.meshes) {
            NSString *name = mesh.displayName;
            NSTextCheckingResult *match = [expression firstMatchInString:name options:NSMatchingAnchored range:NSMakeRange(0, name.length)];
            
            if (match) {
                NSString *partName = [name substringWithRange:[match rangeAtIndex:1]];
                if (![names containsObject:partName]) {
                    [optionalParts addObject:[[GLLOptionalPart alloc] initWithItem:representedItem name:partName]];
                    [names addObject:partName];
                }
            }
        }
    }
    self.parts = optionalParts;
    
    [super setRepresentedObject:representedObject];
}

@end
