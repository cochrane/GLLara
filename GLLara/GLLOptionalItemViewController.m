//
//  GLLOptionalItemViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "GLLOptionalItemViewController.h"

@interface GLLOptionalItemViewController ()

@end

@implementation GLLOptionalItemViewController

- (id)init
{
    self = [super initWithNibName:@"GLLOptionalItemView" bundle:nil];
    if (self) {
        // Initialization code here.
    }
    
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

@end
