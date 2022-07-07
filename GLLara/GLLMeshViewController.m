//
//  GLLMeshViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshViewController.h"

#import "GLLColorRenderParameterView.h"
#import "GLLFloatRenderParameterView.h"
#import "GLLItemMesh.h"
#import "GLLItemMeshSelectionPlaceholder.h"
#import "GLLItemMeshTexture.h"
#import "GLLItemMeshTextureSelectionPlaceholder.h"
#import "GLLRenderParameter.h"
#import "GLLRenderParameterSelectionPlaceholder.h"
#import "GLLSelection.h"
#import "GLLTextureAssignmentView.h"
#import "GLLMultipleSelectionPlaceholder.h"

#import "GLLara-Swift.h"

/************************************************************************
 A very high-level overview:
 
 I have an array controller, whose content is dependent on the selection
 of a tree controller (but not direclty set to; the view-based table
 view didn't work as I wanted it, so I'm rolling my own). The mesh
 objects of the tree controller have parameters with names that are
 unique per mesh, but most meshes wil have parameters of the same
 values. Each entry in the table view allows me to edit one parameter. I
 want that each table view cell can edit the values for multiple
 selection.
 
 Any straightforward implementation is hampered by the fact that you can
 only bind things directly to  a key path containing "selection", you
 can't go through anything that is bound to "selection". To solve this,
 
 a) This controller gets the "selection" proxy as a representedObject,
 with the selectedObjects array as generic fallbac
 b) The items of the view are bound more or less directly to self.
 
 The more or less is what I hate the most; binding directly to selection
 won't work (not sure why), so I've got an array controller set to
 selected objects, all selected, and am using that controller's
 selection proxy for the binding. It works, but I'm really looking for a
 cleaner solution.
 
 Binding something to a specific index in an array (or set!) won't work,
 of course, but I know that each object has its own key here, and that
 two will have the same key if I want to display them together. So with
 some slight hackery, I am using that key as a key for KVC, and bind to
 it. You don't expect to see stringWithFormat… in any KVC or bindings
 code, but this solution doesn't rely on anything undocumented and works.
 
 Getting access to the view is also surprisingly difficult. I have no
 idea what the "owner" parameter does, but it's not what I want it to;
 it doesn't set my outlets. So instead I'm using an NSView subclass that
 contains the outlets to the individual fields. That works. Binding in
 IB is out of the question due to the trick with the dynamically
 generated key path.
 ************************************************************************/

@interface GLLMeshViewController ()
{
    NSArray *renderParameterNames;
    NSArray *textureNames;
}

- (void)_findRenderParameterNames;

@end

@implementation GLLMeshViewController

- (id)initWithSelection:(GLLSelection *)selection managedObjectContext:(NSManagedObjectContext *)context
{
    if (!(self = [super initWithNibName:@"GLLMeshView" bundle:[NSBundle mainBundle]]))
        return nil;
    
    _selection = selection;
    [_selection addObserver:self forKeyPath:@"selectedMeshes" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    _managedObjectContext = context;
    
    _visible = [[GLLItemMeshSelectionPlaceholder alloc] initWithKeyPath:@"isVisible" selection:selection];
    _usingBlending = [[GLLItemMeshSelectionPlaceholder alloc] initWithKeyPath:@"isUsingBlending" selection:selection];
    _selectedShader = [[GLLItemMeshSelectionPlaceholder alloc] initWithKeyPath:@"shader" selection:selection];
    _cullFace = [[GLLItemMeshSelectionPlaceholder alloc] initWithKeyPath:@"cullFaceMode" selection:selection];
        
    return self;
}

- (void)dealloc
{
    [_selection removeObserver:self forKeyPath:@"selectedMeshes"];
}

- (void)loadView
{
    [super loadView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"selectedMeshes"])
    {
        [self _findRenderParameterNames];
    }
    else if ([keyPath isEqual:@"selection.shader"])
    {
        [self _findRenderParameterNames];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Actions

- (IBAction)help:(id)sender;
{
    NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    [[NSHelpManager sharedHelpManager] openHelpAnchor:@"meshes" inBook:locBookName];
}

#pragma mark - Table view

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.renderParametersView)
    {
        NSString *parameterName = [renderParameterNames objectAtIndex:row];
        
        GLLRenderParameterDescription *descriptionForName = nil;
        for (GLLItemMesh *mesh in [self.selection valueForKey:@"selectedMeshes"])
        {
            descriptionForName = [mesh renderParameterWithName:parameterName].parameterDescription;
            if (descriptionForName) break;
        }
        
        if (!descriptionForName)
            return nil;
        
        
        if (descriptionForName.type == GLLRenderParameterTypeColor)
        {
            GLLColorRenderParameterView *result = [tableView makeViewWithIdentifier:@"ColorRenderParameterView" owner:self];
            
            GLLRenderParameterSelectionPlaceholder *descriptionPlaceholder = [[GLLRenderParameterSelectionPlaceholder alloc] initWithParameterName:parameterName keyPath:@"parameterDescription" selection:self.selection];
            
            [result.parameterTitle bind:@"value" toObject:descriptionPlaceholder withKeyPath:@"value.localizedTitle" options:nil];
            [result.parameterDescription bind:@"value" toObject:descriptionPlaceholder withKeyPath:@"value.localizedDescription" options:nil];
            
            GLLRenderParameterSelectionPlaceholder *valuePlaceholder = [[GLLRenderParameterSelectionPlaceholder alloc] initWithParameterName:parameterName keyPath:@"value" selection:self.selection];
            [result.parameterValue bind:@"value" toObject:valuePlaceholder withKeyPath:@"value" options:nil];
            
            return result;
            
        }
        else if (descriptionForName.type == GLLRenderParameterTypeFloat)
        {
            GLLFloatRenderParameterView *result = [tableView makeViewWithIdentifier:@"FloatRenderParameterView" owner:self];
            
            GLLRenderParameterSelectionPlaceholder *descriptionPlaceholder = [[GLLRenderParameterSelectionPlaceholder alloc] initWithParameterName:parameterName keyPath:@"parameterDescription" selection:self.selection];
            
            [result.parameterTitle bind:@"value" toObject:descriptionPlaceholder withKeyPath:@"value.localizedTitle" options:nil];
            [result.parameterDescription bind:@"value" toObject:descriptionPlaceholder withKeyPath:@"value.localizedDescription" options:nil];
            [result.parameterSlider bind:@"minValue" toObject:descriptionPlaceholder withKeyPath:@"value.min" options:nil];
            [result.parameterSlider bind:@"maxValue" toObject:descriptionPlaceholder withKeyPath:@"value.max" options:nil];
            
            GLLRenderParameterSelectionPlaceholder *valuePlaceholder = [[GLLRenderParameterSelectionPlaceholder alloc] initWithParameterName:parameterName keyPath:@"value" selection:self.selection];
            [result.parameterSlider bind:@"value" toObject:valuePlaceholder withKeyPath:@"value" options:nil];
            [result.parameterValueField bind:@"value" toObject:valuePlaceholder withKeyPath:@"value" options:nil];
            
            return result;
        }
        else
            return nil;
    }
    else if (tableView == self.textureAssignmentsView)
    {
        NSString *textureName = [textureNames objectAtIndex:row];
        
        GLLTextureAssignmentView *result = [tableView makeViewWithIdentifier:@"TextureAssignment" owner:self];
        
        GLLMultipleSelectionPlaceholder *textureDescriptionPlaceholder = [[GLLItemMeshTextureSelectionPlaceholder alloc] initWithTextureName:textureName keyPath:@"textureDescription" selection:self.selection];
        
        [result.textureTitle bind:@"value" toObject:textureDescriptionPlaceholder withKeyPath:@"value.localizedTitle" options:nil];
        [result.textureDescription bind:@"value" toObject:textureDescriptionPlaceholder withKeyPath:@"value.localizedDescription" options:nil];
        
        GLLMultipleSelectionPlaceholder *textureURLPlaceholder = [[GLLItemMeshTextureSelectionPlaceholder alloc] initWithTextureName:textureName keyPath:@"textureURL" selection:self.selection];
        
        [result.textureImage bind:@"imageURL" toObject:textureURLPlaceholder withKeyPath:@"value" options:nil];
        
        //viewsForTextureNames[textureName] = result;
        
        //[placeholders addObject:textureDescriptionPlaceholder];
        //[placeholders addObject:textureURLPlaceholder];
        
        return result;
    }
    else
        return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.renderParametersView)
        return renderParameterNames.count;
    else if (tableView == self.textureAssignmentsView)
        return textureNames.count;
    else
        return 0;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // We're using direct bindings instead; the result of this method is completely ignored.
    return nil;
}

#pragma mark - Private methods

- (void)_findRenderParameterNames;
{
    NSArray *selectedMeshes = [self.selection valueForKey:@"selectedMeshes"];
    
    if (selectedMeshes.count == 0)
    {
        renderParameterNames = @[];
        textureNames = @[];
        self.possibleShaders = @[];
        
        [self.renderParametersView reloadData];
        [self.textureAssignmentsView reloadData];
        return;
    }
    
    // Compute intersection of parameter and texture names
    NSMutableSet *parameterNames = [[selectedMeshes[0] valueForKeyPath:@"renderParameters.name"] mutableCopy];
    NSMutableSet *textureNamesSet = [[selectedMeshes[0] valueForKeyPath:@"textures.identifier"] mutableCopy];
    
    for (GLLItemMesh *mesh in selectedMeshes)
    {
        [parameterNames intersectSet:[mesh valueForKeyPath:@"renderParameters.name"]];
        [textureNamesSet intersectSet:[mesh valueForKeyPath:@"textures.identifier"]];
    }
    
    renderParameterNames = [parameterNames sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] ];
    textureNames = [textureNamesSet sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] ];
    
    // Find possible and actual shaders
    self.possibleShaders = @[];
    
    [self.renderParametersView reloadData];
    [self.textureAssignmentsView reloadData];
}

@end
