//
//  ReferrerNames.m
//  ERG2014
//
//  Created by mb on 2014-03-05
//
//

#import "ReferrerNames.h"

@implementation ReferrerNames


NSMutableArray *referrersArray;


- (NSString *) pathOfApplicationContainer {
	NSString *path = [[[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent]
					   stringByDeletingLastPathComponent]
					  stringByDeletingLastPathComponent];
	// NSLog(@"path %@", path);
	return path;
}


- (id) init {   //NSLog(@"%s", __PRETTY_FUNCTION__);
    if ((self = [super init])) {
        NSString *appPath = [self pathOfApplicationContainer];
        [appPath stringByAppendingPathComponent: @"../edgReferrerList.plist"];
        referrersArray = [NSArray arrayWithContentsOfFile: [appPath stringByAppendingPathComponent: @"../edgReferrerList.plist"]];
        if (!referrersArray) referrersArray = [NSArray arrayWithContentsOfFile: [appPath stringByAppendingPathComponent: @"../../edgReferrerList.plist"]];
        if (!referrersArray) referrersArray = [NSArray arrayWithContentsOfFile: [appPath stringByAppendingPathComponent: @"../../../edgReferrerList.plist"]];
        if (!referrersArray) referrersArray = [NSArray arrayWithContentsOfFile: [appPath stringByAppendingPathComponent: @"../../../../edgReferrerList.plist"]];
        if (!referrersArray) referrersArray = [NSArray arrayWithContentsOfFile: [appPath stringByAppendingPathComponent: @"../../../../../edgReferrerList.plist"]];
        if (!referrersArray) referrersArray = [NSArray arrayWithContentsOfFile: [appPath stringByAppendingPathComponent: @"../../../../../../edgReferrerList.plist"]];
        if (!referrersArray) referrersArray = [NSArray arrayWithContentsOfFile: @"/Volumes/edg/KLINIK/edgReferrerList.plist"];
        referrersArray = [[NSMutableArray arrayWithArray: [referrersArray sortedArrayUsingSelector:@selector(compare:)]] retain]; // so complicated because sorting ends up in a non-mutable array
	}
	return self;
}


- (NSUInteger)numberOfItemsInComboBox { //NSLog(@"%s", __PRETTY_FUNCTION__);
	return referrersArray.count;
}


- (id) objectValueForItemAtIndex:(NSUInteger) theIndex {    //NSLog(@"%s", __PRETTY_FUNCTION__);
	return [referrersArray objectAtIndex: theIndex];
}


- (NSUInteger) indexOfItemWithStringValue:(NSString *)string {  //NSLog(@"%s", __PRETTY_FUNCTION__);
    return [referrersArray indexOfObject: string];
}


- (NSString *) firstDoctorMatchingPrefix:(NSString *)prefix {  //NSLog(@"%s", __PRETTY_FUNCTION__);
    //    NSString *string = nil, *lowercasePrefix = [prefix lowercaseString];
    //    NSEnumerator *stringEnum = [referrersArray objectEnumerator];
    //   while ((string = [stringEnum nextObject]))
    //		if ([[string lowercaseString] hasPrefix: lowercasePrefix]) return string;
	for (NSString *string in referrersArray) {
		if ([[string lowercaseString] hasPrefix: [prefix lowercaseString]]) return string;
	}
    return nil;
}


- (NSString *) completedString:(NSString *)inputString {    //NSLog(@"%s", __PRETTY_FUNCTION__);
    // This method is received after each character typed by the user, because we have checked the "completes" flag for genreComboBox in IB.
    // Given the inputString the user has typed, see if we can find a doctor with the prefix, and return it as the suggested complete string.
    NSString *candidate = [self firstDoctorMatchingPrefix: inputString];
    return (candidate ? candidate : inputString);
}


@end
