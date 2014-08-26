//
//  PrefsController.h
//  ERG2007
//
//  Created by bach on 14.01.07.
//  Copyright 2007 Prof. Michael Bach. All rights reserved.
//
//	History
//	=======
//

#import <Cocoa/Cocoa.h>
#import "Globals.h"


@interface PrefsController: NSUserDefaultsController {
}

- (CGFloat) amplificationFactor;
- (void) setAmplificationFactor: (CGFloat) theValue;

- (NSColor *) osciTraceColor;
- (void) setOsciTraceColor: (NSColor *) theColor;

- (BOOL) menuBarVisible;
- (void) setMenuBarVisible: (BOOL) theState;

- (BOOL) autoHideOtherApplications;
- (void) setAutoHideOtherApplications: (BOOL) theState;

- (void) setSubjectname: (NSString *) s;

- (void) setEPNumber: (NSInteger) theValue;
- (NSInteger) epNumber;

@end
