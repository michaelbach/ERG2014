//
//  ReferrerNames.h
//  ERG2014
//
//  Created by mb on 2014-03-05
//
//  These are routines that deal with the combobox of the referrer names (doctors etc.)
//  Separated in this rather special class to make the MainController smaller
//


#import <Cocoa/Cocoa.h>

@interface ReferrerNames : NSObject


- (NSUInteger) numberOfItemsInComboBox;

- (id) objectValueForItemAtIndex: (NSUInteger) theIndex;

- (NSUInteger) indexOfItemWithStringValue:(NSString *)string;

- (NSString *) completedString: (NSString *)inputString;

@end
