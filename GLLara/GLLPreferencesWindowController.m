//
//  GLLPreferencesWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.12.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLPreferencesWindowController.h"

#import "GLLResourceManager.h"

@interface GLLPreferencesWindowController ()

@property (nonatomic, readwrite, assign) NSUInteger maxAnisotropyLevel;

@end

@implementation GLLPreferencesWindowController

- (instancetype)init {
    return [self initWithWindowNibName:@"GLLPreferencesWindow" owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    self.maxAnisotropyLevel = [[GLLResourceManager sharedResourceManager] maxAnisotropyLevel];
}

@end
