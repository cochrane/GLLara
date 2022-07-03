//
//  GLLRenderWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindowController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "GLLCamera.h"
#import "GLLDocument.h"
#import "GLLView.h"
#import "GLLRenderAccessoryViewController.h"
#import "GLLSceneDrawer.h"
#import "GLLViewDrawer.h"

@interface GLLRenderWindowController ()
{
    GLLRenderAccessoryViewController *savePanelAccessoryViewController;
    BOOL showingPopover;
}

@property (nonatomic, retain, readwrite) GLLCamera *camera;

@end

@implementation GLLRenderWindowController

- (id)initWithCamera:(GLLCamera *)camera sceneDrawer:(GLLSceneDrawer *)sceneDrawer;
{
    if (!(self = [super initWithWindowNibName:@"GLLRenderWindowController"]))
        return nil;
    
    _camera = camera;
    _sceneDrawer = sceneDrawer;
    savePanelAccessoryViewController = [[GLLRenderAccessoryViewController alloc] init];
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
        
    self.popoverButton.image.template = YES;
    for (NSInteger i = 0; i < self.selectionModeControl.segmentCount; i++)
        [[self.selectionModeControl imageForSegment:i] setTemplate:YES];
    
    self.window.delegate = self;
    
    [self.renderView setCamera:self.camera sceneDrawer:self.sceneDrawer];
    self.popover.delegate = self;
    
    [self.camera addObserver:self forKeyPath:@"windowWidth" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                     context:NULL];
    [self.camera addObserver:self forKeyPath:@"windowHeight" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                     context:NULL];
    [self.camera addObserver:self forKeyPath:@"windowSizeLocked" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                     context:NULL];
    
    self.renderView.document = self.document;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSSize contentSize = [self.window.contentView frame].size;
    
    if ([keyPath isEqual:@"windowWidth"])
    {
        if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
        {
            [self close];
            return;
        }
        self.window.contentSize = NSMakeSize([change[NSKeyValueChangeNewKey] doubleValue], contentSize.height);
    }
    else if ([keyPath isEqual:@"windowHeight"])
    {
        if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
        {
            [self close];
            return;
        }
        self.window.contentSize = NSMakeSize(contentSize.width, [change[NSKeyValueChangeNewKey] doubleValue]);
    }
    else if ([keyPath isEqual:@"windowSizeLocked"])
    {
        if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
        {
            [self close];
            return;
        }
        NSUInteger styleMask = self.window.styleMask;
        styleMask = styleMask & ~NSWindowStyleMaskResizable; // Clear resizable window mask bit (if it was set)
        if (![change[NSKeyValueChangeNewKey] boolValue])
            styleMask = styleMask | NSWindowStyleMaskResizable; // Set it
        
        [[self.window standardWindowButton:NSWindowZoomButton] setEnabled:![change[NSKeyValueChangeNewKey] boolValue]];
        self.window.styleMask = styleMask;
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:0];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.camera.managedObjectContext;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return [NSString stringWithFormat:NSLocalizedString(@"%@ - Render view %lld", @"render window title format"), displayName, self.camera.index + 1];
}

#pragma mark - Actions

- (IBAction)renderToFile:(id)sender
{
    NSRect rect = NSMakeRect(0, 0, self.camera.actualWindowWidth, self.camera.actualWindowHeight);
    NSRect pixelRect = [self.window convertRectToBacking:rect];
    NSMutableDictionary *saveData = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                    @"width" : @(pixelRect.size.width),
                                                                                    @"height" : @(pixelRect.size.height),
                                                                                    @"maxSamples" : @8,
                                                                                    }];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanelAccessoryViewController.representedObject = saveData;
    savePanelAccessoryViewController.savePanel = savePanel;
    savePanel.accessoryView = savePanelAccessoryViewController.view;
    
    NSArray *allowedTypeIdentifiers = (__bridge_transfer NSArray *) CGImageDestinationCopyTypeIdentifiers();
    NSMutableArray<UTType*>* allowedTypes = [NSMutableArray arrayWithCapacity:allowedTypeIdentifiers.count];
    for (NSString *identifier in allowedTypeIdentifiers) {
        [allowedTypes addObject:[UTType typeWithIdentifier:identifier]];
    }
    savePanel.allowedContentTypes = allowedTypes;
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result != NSModalResponseOK) return;
        
        NSUInteger width = [saveData[@"width"] unsignedIntegerValue];
        NSUInteger height = [saveData[@"height"] unsignedIntegerValue];
        
        [self renderToFile:savePanel.URL type:self->savePanelAccessoryViewController.selectedTypeIdentifier width:width height:height];
    }];
}

- (void)renderToFile:(NSURL *)file type:(NSString *)typeUTI width:(NSUInteger)width height:(NSUInteger)height;
{
    [self.renderView.viewDrawer writeImageToURL:file fileType:typeUTI size:CGSizeMake(width, height)];
}

#pragma mark - Popover

- (IBAction)showPopoverFrom:(id)sender;
{
    if (showingPopover)
        [self.popover close];
    else
    {
        self.popover.contentViewController.representedObject = self.camera;
        [self.popover showRelativeToRect:[sender frame] ofView:[sender superview] preferredEdge:NSMinYEdge];
        showingPopover = YES;
    }
}

- (void)popoverDidClose:(NSNotification *)notification
{
    showingPopover = NO;
}

#pragma mark - Window delegate

- (BOOL)windowShouldClose:(id)sender
{
    [self.camera removeObserver:self forKeyPath:@"windowWidth"];
    [self.camera removeObserver:self forKeyPath:@"windowHeight"];
    [self.camera removeObserver:self forKeyPath:@"windowSizeLocked"];
    [self.renderView unload];
    
    [self.managedObjectContext deleteObject:self.camera];
    
    self.camera = nil;
    self.popover.delegate = nil;
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.camera removeObserver:self forKeyPath:@"windowWidth"];
    [self.camera removeObserver:self forKeyPath:@"windowHeight"];
    [self.camera removeObserver:self forKeyPath:@"windowSizeLocked"];
    [self.renderView unload];
    self.camera = nil;
    self.popover.delegate = nil;
}

@end
