//
//  Misc.m
//  ERG2007
//
//  Created by bach on 15.02.10.
//  Copyright 2010 Universitäts-Augenklinik. All rights reserved.
//

#import "Misc.h"


@implementation Misc


+ (NSString *) pathOfApplicationContainer {
	//	NSString *path = [[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier: @"de.michaelbach.ERG2007"] stringByDeletingLastPathComponent];
	NSString *path = [[[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] 
					   stringByDeletingLastPathComponent] 
					  stringByDeletingLastPathComponent];
	// NSLog(@"path %@", path);
	return path;
}


+ (NSString *) date2YYYY_MM_DD: (NSDate *) theDate {
	return [theDate descriptionWithCalendarFormat:
            @"%Y-%m-%d" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


+ (NSString *) date2HH_MM_SS: (NSDate *) theDate {
	return [theDate descriptionWithCalendarFormat:
            @"%H:%M:%S" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


+ (NSString *) date2HH_MM_SSdotted: (NSDate *) theDate {
	return [theDate descriptionWithCalendarFormat:
            @"%H.%M.%S" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


+ (NSString *) epNum2fullString: (NSUInteger) epNum {
    return [NSString stringWithFormat: @"ERG%05u-", epNum];
}


+ (NSString *) string2MacOSRomanLossy: (NSString*) inString {
	NSData *dta=[inString dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion: YES];
	NSString *aString = [[[NSString alloc] initWithData:dta encoding: NSMacOSRomanStringEncoding] autorelease];
	return aString;
}

@end
