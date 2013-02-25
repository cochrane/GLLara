//  DMLocalizedNibBundle.m
//
//  Created by William Jon Shipley on 2/13/05.
//  Copyright © 2005-2009 Golden % Braeburn, LLC. All rights reserved except as below:
//  This code is provided as-is, with no warranties or anything. You may use it in your projects as you wish, but you must leave this comment block (credits and copyright) intact. That's the only restriction -- Golden % Braeburn otherwise grants you a fully-paid, worldwide, transferrable license to use this code as you see fit, including but not limited to making derivative works.


#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>


@interface NSBundle (DMLocalizedNibBundle)
+ (BOOL)deliciousLocalizingLoadNibFile:(NSString *)fileName externalNameTable:(NSDictionary *)context withZone:(NSZone *)zone;
@end

@interface NSBundle (DMLocalizedNibBundle_Private)
+ (void)_localizeStringsInObject:(id)object table:(NSString *)table;
+ (NSString *)_localizedStringForString:(NSString *)string table:(NSString *)table;
// localize particular attributes in objects
+ (void)_localizeTitleOfObject:(id)object table:(NSString *)table;
+ (void)_localizeAlternateTitleOfObject:(id)object table:(NSString *)table;
+ (void)_localizeStringValueOfObject:(id)object table:(NSString *)table;
+ (void)_localizePlaceholderStringOfObject:(id)object table:(NSString *)table;
+ (void)_localizeToolTipOfObject:(id)object table:(NSString *)table;
+ (void)_localizeLabelOfObject:(id)object table:(NSString *)table;
@end


@implementation NSBundle (DMLocalizedNibBundle)

#pragma mark NSObject

+ (void)load;
{
    NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    if (self == [NSBundle class]) {
        method_exchangeImplementations(class_getClassMethod(self, @selector(loadNibFile:externalNameTable:withZone:)), class_getClassMethod(self, @selector(deliciousLocalizingLoadNibFile:externalNameTable:withZone:)));
        method_exchangeImplementations(class_getInstanceMethod(self, @selector(loadNibNamed:owner:topLevelObjects:)), class_getInstanceMethod(self, @selector(deliciousLocalizingLoadNibNamed:owner:topLevelObjects:)));
    }
    [autoreleasePool release];
}


#pragma mark API

+ (BOOL)deliciousLocalizingLoadNibFile:(NSString *)fileName externalNameTable:(NSDictionary *)context withZone:(NSZone *)zone;
{
    NSString *localizedStringsTableName = [[fileName lastPathComponent] stringByDeletingPathExtension];
    NSString *localizedStringsTablePath = [[NSBundle mainBundle] pathForResource:localizedStringsTableName ofType:@"strings"];
    if (localizedStringsTablePath && ![[[localizedStringsTablePath stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"English.lproj"]) {
        
        NSNib *nib = [[NSNib alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fileName]];
        NSMutableArray *topLevelObjectsArray = [context objectForKey:NSNibTopLevelObjects];
        if (!topLevelObjectsArray) {
            topLevelObjectsArray = [NSMutableArray array];
            context = [NSMutableDictionary dictionaryWithDictionary:context];
            [(NSMutableDictionary *)context setObject:topLevelObjectsArray forKey:NSNibTopLevelObjects];
        }
        BOOL success = [nib instantiateNibWithExternalNameTable:context];
        [self _localizeStringsInObject:topLevelObjectsArray table:localizedStringsTableName];
        
        [nib release];
        return success;
        
    } else {
        return [self deliciousLocalizingLoadNibFile:fileName externalNameTable:context withZone:zone];
    }
}

- (BOOL)deliciousLocalizingLoadNibNamed:(NSString *)nibName owner:(id)owner topLevelObjects:(NSArray **)topLevelObjects
{
	BOOL success = [self deliciousLocalizingLoadNibNamed:nibName owner:owner topLevelObjects:topLevelObjects];
	
	NSString *localizedStringsTableName = [[nibName lastPathComponent] stringByDeletingPathExtension];
    NSString *localizedStringsTablePath = [[NSBundle mainBundle] pathForResource:localizedStringsTableName ofType:@"strings"];
	
	if (localizedStringsTablePath && ![[[localizedStringsTablePath stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"English.lproj"])
	{
        [[self class] _localizeStringsInObject:*topLevelObjects table:localizedStringsTableName];
	}
	
	return success;
}



#pragma mark Private API

+ (void)_localizeStringsInObject:(id)object table:(NSString *)table;
{
    if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = object;
        
        for (id nibItem in array)
            [self _localizeStringsInObject:nibItem table:table];
		
    } else if ([object isKindOfClass:[NSCell class]]) {
        NSCell *cell = object;
        
        if ([cell isKindOfClass:[NSActionCell class]]) {
            NSActionCell *actionCell = (NSActionCell *)cell;
            
            if ([actionCell isKindOfClass:[NSButtonCell class]]) {
                NSButtonCell *buttonCell = (NSButtonCell *)actionCell;
                if ([buttonCell imagePosition] != NSImageOnly) {
                    [self _localizeTitleOfObject:buttonCell table:table];
                    [self _localizeStringValueOfObject:buttonCell table:table];
                    [self _localizeAlternateTitleOfObject:buttonCell table:table];
                }
            } else if ([actionCell isKindOfClass:[NSTokenFieldCell class]]) {
                // Don't localize the string value of token fields because
                // calling the setStringValue method because this causes custom
                // (= non-strings) token objects to be converted to strings.
                // You can see this because suddenly NSTokenFieldDelegate's
                // tokenField:representedObjectForEditingString: when launching
                // the app in a localized language, but not called for the
                // English version.
                NSTokenFieldCell *tokenFieldCell = (NSTokenFieldCell *)actionCell;
                [self _localizePlaceholderStringOfObject:tokenFieldCell table:table];
            } else if ([actionCell isKindOfClass:[NSTextFieldCell class]]) {
                NSTextFieldCell *textFieldCell = (NSTextFieldCell *)actionCell;
                // Following line is redundant with other code, localizes twice.
                // [self _localizeTitleOfObject:textFieldCell table:table];
                [self _localizeStringValueOfObject:textFieldCell table:table];
                [self _localizePlaceholderStringOfObject:textFieldCell table:table];
				
            } else if ([actionCell type] == NSTextCellType) {
                [self _localizeTitleOfObject:actionCell table:table];
                [self _localizeStringValueOfObject:actionCell table:table];
            }
        }
        
    } else if ([object isKindOfClass:[NSMenu class]]) {
        NSMenu *menu = object;
        [self _localizeTitleOfObject:menu table:table];
        
        [self _localizeStringsInObject:[menu itemArray] table:table];
        
    } else if ([object isKindOfClass:[NSMenuItem class]]) {
        NSMenuItem *menuItem = object;
        [self _localizeTitleOfObject:menuItem table:table];
        
        [self _localizeStringsInObject:[menuItem submenu] table:table];
        
    } else if ([object isKindOfClass:[NSView class]]) {
        NSView *view = object;
        [self _localizeToolTipOfObject:view table:table];
		
        if ([view isKindOfClass:[NSBox class]]) {
            NSBox *box = (NSBox *)view;
            [self _localizeTitleOfObject:box table:table];
            
        } else if ([view isKindOfClass:[NSControl class]]) {
            NSControl *control = (NSControl *)view;
			
			// Localize display patterns in text fields (non-trivial because they're only accessible via bindings)
			if ([view isKindOfClass:[NSTextField class]]) {
				NSTextField *textField = (NSTextField *)control;
				
				// A text field can have more than one display pattern binding (displayPatternValue1, ...) but according to the Apple
				// docs its sufficient to change the first one and the change will be rippled through to the other ones
				if ([[textField exposedBindings] containsObject:@"displayPatternValue1"]) {
					NSDictionary *displayPatternInfo = [textField infoForBinding:@"displayPatternValue1"];
					if (displayPatternInfo) {
						// First get the unlocalized display pattern string from the bindings info and localize it
						NSString *unlocalizedDisplayPattern = [[displayPatternInfo objectForKey:NSOptionsKey] objectForKey:NSDisplayPatternBindingOption];
						NSString *localizedDisplayPattern = [[NSBundle mainBundle] localizedStringForKey:unlocalizedDisplayPattern value:unlocalizedDisplayPattern table:table];
						
						// To actually update the display pattern we need to re-create the bindings
						NSMutableDictionary *localizedOptions = [[displayPatternInfo objectForKey:NSOptionsKey] mutableCopy];
						[localizedOptions setObject:localizedDisplayPattern forKey:NSDisplayPatternBindingOption];
						[textField bind:@"displayPatternValue1" toObject:[displayPatternInfo objectForKey:NSObservedObjectKey] withKeyPath:[displayPatternInfo objectForKey:NSObservedKeyPathKey] options:localizedOptions];
					}
				}
			}
			
            if ([view isKindOfClass:[NSButton class]]) {
                NSButton *button = (NSButton *)control;
				
                if ([button isKindOfClass:[NSPopUpButton class]]) {
                    NSPopUpButton *popUpButton = (NSPopUpButton *)button;
                    NSMenu *menu = [popUpButton menu];
                    
                    [self _localizeStringsInObject:[menu itemArray] table:table];
                } else
                    [self _localizeStringsInObject:[button cell] table:table];
				
                
            } else if ([view isKindOfClass:[NSMatrix class]]) {
                NSMatrix *matrix = (NSMatrix *)control;
                
                NSArray *cells = [matrix cells];
                [self _localizeStringsInObject:cells table:table];
                
                for (NSCell *cell in cells) {
                    
                    NSString *localizedCellToolTip = [self _localizedStringForString:[matrix toolTipForCell:cell] table:table];
                    if (localizedCellToolTip)
                        [matrix setToolTip:localizedCellToolTip forCell:cell];
                }
                
            } else if ([view isKindOfClass:[NSSegmentedControl class]]) {
                NSSegmentedControl *segmentedControl = (NSSegmentedControl *)control;
                
                NSUInteger segmentIndex, segmentCount = [segmentedControl segmentCount];
                for (segmentIndex = 0; segmentIndex < segmentCount; segmentIndex++) {
                    NSString *localizedSegmentLabel = [self _localizedStringForString:[segmentedControl labelForSegment:segmentIndex] table:table];
                    if (localizedSegmentLabel)
                        [segmentedControl setLabel:localizedSegmentLabel forSegment:segmentIndex];
                    
                    [self _localizeStringsInObject:[segmentedControl menuForSegment:segmentIndex] table:table];
                }
                
            } else if ([object isKindOfClass:[NSTableView class]]) {   // table and outline views
				NSTableView *tableView = object;
				NSArray *tableColumns = [tableView tableColumns];
				[self _localizeStringsInObject:tableColumns table:table];
			}
			else
                [self _localizeStringsInObject:[control cell] table:table];
			
        } else if ([object isKindOfClass:[NSTabView class]]) {
			NSTabView *tabView = object;
			[self _localizeStringsInObject:[tabView tabViewItems] table:table];
		}
        
        [self _localizeStringsInObject:[view subviews] table:table];
        
    } else if ([object isKindOfClass:[NSWindow class]]) {
        NSWindow *window = object;
        [self _localizeTitleOfObject:window table:table];
        
        [self _localizeStringsInObject:[window contentView] table:table];
        
    } else if ([object isKindOfClass:[NSTabViewItem class]]) {
		NSTabViewItem *tabViewItem = object;
		[self _localizeLabelOfObject:object table:table];
        [self _localizeStringsInObject:[tabViewItem view] table:table];
    } else if ([object isKindOfClass:[NSTableColumn class]]) {
		NSTableColumn *tableColumn = object;
        [self _localizeTitleOfObject:[tableColumn headerCell] table:table];
    }
}

+ (NSString *)_localizedStringForString:(NSString *)string table:(NSString *)table;
{
    if (![string length])
        return nil;
	
    static NSString *defaultValue = @"I AM THE DEFAULT VALUE";
    NSString *localizedString = [[NSBundle mainBundle] localizedStringForKey:string value:defaultValue table:table];
    if (localizedString != defaultValue) {
        return localizedString;
    } else { 
#ifdef BETA_BUILD
        NSLog(@"        not going to localize string %@", string);
        return string; // [string uppercaseString]
#else
        return string;
#endif
    }
}


#define DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(blahName, capitalizedBlahName) \
+ (void)_localize ##capitalizedBlahName ##OfObject:(id)object table:(NSString *)table; \
{ \
NSString *localizedBlah = [self _localizedStringForString:[object blahName] table:table]; \
if (localizedBlah) \
[object set ##capitalizedBlahName:localizedBlah]; \
}

DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(title, Title)
DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(alternateTitle, AlternateTitle)
DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(stringValue, StringValue)
DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(placeholderString, PlaceholderString)
DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(toolTip, ToolTip)
DM_DEFINE_LOCALIZE_BLAH_OF_OBJECT(label, Label)

@end
