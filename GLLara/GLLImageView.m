//
//  GLLImageView.m
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLImageView.h"

@interface GLLImageView ()

@property (nonatomic, weak) id imageURLController;
@property (nonatomic, copy) NSString *imageURLControllerPath;

@end

@implementation GLLImageView

+ (void)initialize
{
    [self exposeBinding:@"imageURL"];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    self.imageURL = [NSURL URLFromPasteboard:sender.draggingPasteboard];
    
    [super concludeDragOperation:sender];
}

- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    if ([binding isEqual:@"imageURL"])
    {
        self.imageURLController = observable;
        self.imageURLControllerPath = keyPath;
    }
    
    [super bind:binding toObject:observable withKeyPath:keyPath options:options];
}

- (void)unbind:(NSString *)binding
{
    if ([binding isEqual:@"imageURL"])
    {
        self.imageURLController = nil;
        self.imageURLControllerPath = nil;
    }
    
    [super unbind:binding];
}

- (void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
    self.image = [[NSImage alloc] initByReferencingURL:imageURL];
    
    // Do not update if the new value is nil. This is based on the theory that
    // the ui doesn't allow deletion of the texture, so a nil argument will only
    // be used while the binding is switching and when setting the value is not
    // reliable anyway.
    if (imageURL != nil)
        [self.imageURLController setValue:imageURL forKeyPath:self.imageURLControllerPath];
}

@end
