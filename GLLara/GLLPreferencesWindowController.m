//
//  GLLPreferencesWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.12.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLPreferencesWindowController.h"

#import "GLLara-Swift.h"

@interface GLLPreferencesWindowController ()

@end

static id graphicsPreferences = @"GraphicsPreferences";
static id controllerPreferences = @"ControllerPreferences";

@implementation GLLPreferencesWindowController

- (instancetype)init {
    return [self initWithWindowNibName:@"GLLPreferencesWindow" owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.pageController.arrangedObjects = @[ graphicsPreferences, controllerPreferences ];
    self.pageController.selectedIndex = 0;
    self.toolbar.selectedItemIdentifier = self.pageController.arrangedObjects[self.pageController.selectedIndex];
}

- (void)navigateToPage:(id)sender {
    NSString *identifier = ((NSToolbarItem *) sender).itemIdentifier;
    NSInteger index = [self.pageController.arrangedObjects indexOfObject:identifier];
    if (index != NSNotFound) {
        self.pageController.selectedIndex = index;
    }
    self.toolbar.selectedItemIdentifier = identifier;
}

- (NSPageControllerObjectIdentifier)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    if ([object isEqual:graphicsPreferences])
        return graphicsPreferences;
    else if ([object isEqual:controllerPreferences]) {
        return controllerPreferences;
    }
    return nil;
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSPageControllerObjectIdentifier)identifier {
    if ([identifier isEqual:graphicsPreferences]) {
        return [[GLLDrawingPreferencesViewController alloc] init];
    } else if ([identifier isEqual:controllerPreferences]) {
        return [[GLLControllerPreferencesViewController alloc] init];
    }
    return nil;
}

@end
