//
//  PrefsController.m
//  ERG2007
//
//  Created by bach on 14.01.07.
//  Copyright 2007 Prof. Michael Bach. All rights reserved.
//

#import "PrefsController.h"

@implementation PrefsController


- (id) init { //    NSLog(@"%s", __PRETTY_FUNCTION__);
	self = [super init];
	if (self != nil) {	//	NSLog(@"ERG2007>PrefsController>init\n");
		[[NSUserDefaults standardUserDefaults] setObject: @kCurrentVersionDate forKey: @kKeyVersion];

		CGFloat amplFactor = [[NSUserDefaults standardUserDefaults] floatForKey: @kKeyAmplificationFactor];
        //NSLog(@"amplFactor: %f", amplFactor);
		if (amplFactor <= 0) {
			NSInteger result = NSRunAlertPanel(@"Preferences not found.", @"Create?", @"OK", @"Quit", NULL);
			if (result != NSAlertDefaultReturn)	[NSApp terminate:nil];

			[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithFloat: kDefaultAmplificationFactor]
													  forKey: @kKeyAmplificationFactor];

			NSData *theData=[NSArchiver archivedDataWithRootObject: [NSColor blackColor]]; 
			[[NSUserDefaults standardUserDefaults] setObject: theData forKey:@"oscilloscope0Color"];
		}
	}
	return self;
}


- (void) dealloc {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	[super dealloc];
}


- (void) applicationWillTerminate:(NSNotification *)notification{
	#pragma unused (notification)
    [self release]; // to make sure we do get released.
}


- (CGFloat) amplificationFactor {   //  NSLog(@"%s", __PRETTY_FUNCTION__);
    return [[NSUserDefaults standardUserDefaults] floatForKey: @kKeyAmplificationFactor];
}

- (void) setAmplificationFactor: (CGFloat) theValue {
    NSAssert(theValue > 0 && theValue <= 1E7, @"amplificationFactor was <= 0 or > 1E7");
    [[NSUserDefaults standardUserDefaults] setFloat: theValue forKey: @kKeyAmplificationFactor];
}


- (NSColor *) osciTraceColor {
	NSColor *aColor = [NSColor blackColor];
	NSData *theData=[[NSUserDefaults standardUserDefaults] dataForKey: @"osciTraceColor"];
	if (theData != nil) 
		aColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData: theData]; 
	return aColor;
}
- (void) setOsciTraceColor: (NSColor *) theColor {
	NSData *theData=[NSArchiver archivedDataWithRootObject: theColor];
	[[NSUserDefaults standardUserDefaults] setObject: theData forKey: @"osciTraceColor"];
}


- (BOOL) menuBarVisible { return [[NSUserDefaults standardUserDefaults] boolForKey: @"menuBarVisible"]; }
- (void) setMenuBarVisible: (BOOL) theState { [[NSUserDefaults standardUserDefaults] setBool:theState forKey: @"menuBarVisible"]; }


- (BOOL) autoHideOtherApplications { return [[NSUserDefaults standardUserDefaults] boolForKey: @"autoHideOtherApplications"]; }
- (void) setAutoHideOtherApplications: (BOOL) theState { [[NSUserDefaults standardUserDefaults] setBool:theState forKey: @"autoHideOtherApplications"]; }


- (void) setSubjectname: (NSString *) s { [[NSUserDefaults standardUserDefaults] setObject: s forKey: @kKeySubjectName]; }

- (void) setEPNumber: (NSInteger) theValue { [[NSUserDefaults standardUserDefaults] setInteger:theValue forKey: @kKeyEPNumber]; }
- (NSInteger) epNumber { return [[NSUserDefaults standardUserDefaults] integerForKey: @kKeyEPNumber]; }


@end
