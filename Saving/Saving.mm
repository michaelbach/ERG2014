//
//  Saving.m
//  ERG2007
//
//  Created by bach on 07.01.07.
//  Copyright 2007 Prof. Michael Bach. All rights reserved.
//

#import "Saving.h"
#import "Misc.h"

@implementation Saving


@synthesize amplificationFactor;


///// first internal-only functions
- (NSString *) composeWaveNameFromBlockNum: (int) blk andStimNum: (int) stm andChannel: (int) chn { //	ERG2007>Saving>NSLog(@"composeWaveNameWithBlockNum");
	NSMutableString *s = [NSMutableString stringWithString: @"bloc"];
	[s appendString: [[NSNumber numberWithInt: blk] stringValue]];
	[s appendString: @"stim"];  [s appendString: [[NSNumber numberWithInt:stm] stringValue]];
	[s appendString: @"chan"];  [s appendString: [[NSNumber numberWithInt:chn] stringValue]];
	//	NSLog(@"ERG2007>Saving>composeWaveNameWithBlockNum: %@", s);
	return s;
}


- (NSString *) pathToERGFileGivenEPNum: (int) epNum {
	// the EPNum ist preceded by leading zeros up to a length of 5: "EP00123.itx"
	return [[Misc pathOfApplicationContainer] stringByAppendingPathComponent: [NSString stringWithFormat: @"ERG%05u.itx", epNum]];
}
////////////////////////////////////


- (id) init {
	if ((self = [super init])) {	// NSLog(@"ERG2007>Saving>init\n");
	}
	return self;
}


- (void) dealloc {	//	NSLog(@"ERG2007>Saving>dealloc\n");
	[super dealloc];
}


- (CGFloat) detectFlashTime: (NSArray *) tFlash {
// the negative flank is the trigger point
// simple algorithm: find min and max, define 50% as the trigger threshold. Start at left and find 1st value that's above it
#define kMaxTrace 100
	CGFloat trace[kMaxTrace];
	NSEnumerator *enumerator = [tFlash objectEnumerator];
	id anElement;
	NSUInteger index=0;
	while ((anElement = [enumerator nextObject]) && (index < kMaxTrace)) {
		trace[index] = [anElement floatValue]; ++index;
	}
	NSUInteger n = index;
	CGFloat trace0=[[tFlash objectAtIndex:0] floatValue];
	CGFloat theMin=trace0, theMax=theMin;
	for (NSUInteger i=1; i<n; ++i) {
		CGFloat t = trace[i];
		if (t < theMin) theMin = t;
		else {
			if (t > theMax) theMax = t;
		}
	}
	CGFloat halfValue = theMin + (theMax-theMin)/((CGFloat)2.0);
	//	NSLog(@"n: %d, min: %g, max: %g, halfValue: %g", n, theMin, theMax, halfValue);
	if (trace0 < halfValue) return 0;	// if we are below 50% already at the beginning, give up returning 0
	for (index=1; index<n; ++index)
		if (trace[index] < halfValue)  return index;
	NSInteger result = NSRunAlertPanel(@"Problem saving:", 
		[NSString stringWithFormat: @"Flash time evaluated as %lu, this is unlikely high.", (unsigned long)index],
			@"Accept", @"set to 0", @"Quit");
	if (result == NSAlertAlternateReturn)	return 0;
	if (result == NSAlertOtherReturn)		[NSApp terminate:nil];
	//if (result == NSAlertDefaultReturn)
	return index;
}

- (void) test1id: (id) owner {
    //NSLog(@"%d", [owner epNum]);
}


- (void) saveTracesOD: (NSArray *) tOD andOS: (NSArray *) tOS andFlash: (NSArray *) tFlash andDict: (NSDictionary *) d {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	// if hardware is missing, we are in demo mode, and can't detect the flash time anyway.
	CGFloat timeOfFlash = [[d objectForKey: @kKeyisHardwareOk] boolValue] ? [self detectFlashTime: tFlash] : 0;
	//	NSLog(@"timeOfFlash: %d", (NSInteger)timeOfFlash);
	
	NSInteger epNum = [[d objectForKey: @kKeyEPNumber] intValue];
	NSMutableString *ergFileString = [NSMutableString stringWithContentsOfFile: [self pathToERGFileGivenEPNum: epNum] encoding:NSMacOSRomanStringEncoding error: NULL];
	if (ergFileString.length <1) {
		ergFileString = [NSMutableString stringWithCapacity: 10000]; [ergFileString appendString: @"IGOR\n"];
	}
	NSInteger blockNum = [[d objectForKey: @kKeyBlockNumber] intValue];//	NSLog(@"saveTraces, block: %d", blockNum);
	NSInteger stimNum = [[d objectForKey: @kKeyStimNumber] intValue];	//	NSLog(@"saveTraces, stimNum: %d", stimNum);
	NSString *waveOD, *waveOS, *waveFlash;
	waveOD = [self composeWaveNameFromBlockNum: blockNum andStimNum: stimNum andChannel: 0];
	waveOS = [self composeWaveNameFromBlockNum: blockNum andStimNum: stimNum andChannel: 1];
	waveFlash = [self composeWaveNameFromBlockNum: blockNum andStimNum: stimNum andChannel: 2];
	NSArray *waveNameArray = [NSArray arrayWithObjects: waveOD, waveOS, waveFlash, nil];

	[ergFileString appendString: @"WAVES /O "];
	for (NSUInteger i=0; i<waveNameArray.count; ++i) {
		[ergFileString appendString: [waveNameArray objectAtIndex: i]];  [ergFileString appendString: @" "];
	}
	[ergFileString appendString: @"\nBEGIN\n"];
	CGFloat scaleFactor = 1.0 / [self amplificationFactor];//[[d objectForKey: @kKeyAmplificationFactor] floatValue];
	for (NSUInteger i=0; i<tOD.count; ++i) {
		[ergFileString appendFormat: @"%.3e\t", [[tOD objectAtIndex: i] floatValue] * scaleFactor];
#ifdef versionTinaTsai
		[ergFileString appendFormat: @"%.3e\t", [[tOS objectAtIndex: i] floatValue] * scaleFactor / kTinatTsaiVEPAmplificationMultiplier];// added "/30.0"
#else
		[ergFileString appendFormat: @"%.3e\t", [[tOS objectAtIndex: i] floatValue] * scaleFactor];
#endif
		[ergFileString appendFormat: @"%.3e\n", [[tFlash objectAtIndex: i] floatValue] * scaleFactor];
	}
	[ergFileString appendString: @"END\n"];
	
	for (NSUInteger i=0; i<waveNameArray.count; ++i) {
		[ergFileString appendFormat: @"X SetScale /P x %g, %g, \"s\" %@\n", -timeOfFlash/1000.0, kSampleIntervalERGInMs, [waveNameArray objectAtIndex: i]];
		[ergFileString appendFormat: @"X SetScale y -1, 1, \"V\" %@\n", [waveNameArray objectAtIndex: i]];
	}

	for (NSUInteger i=0; i<(waveNameArray.count-1); ++i) {	// we don't need these details for the highest channel, which contains the trigger, so "count-1"
		NSString *ws = [waveNameArray objectAtIndex: i];
		[ergFileString appendFormat: @"X note %@, \"%s:%@;", ws, kKeyVersion, @kCurrentVersionDate];
		[ergFileString appendFormat: @"%s:%ld;", kKeyEPNumber, (long)epNum];
		[ergFileString appendFormat: @"%s:%ld;", kKeyBlockNumber, (long)blockNum];
		[ergFileString appendFormat: @"%s:%ld;", kKeyStimNumber, (long)stimNum];
		[ergFileString appendFormat: @"%s:%lu;", kKeyChannel, (unsigned long)i];
		[ergFileString appendFormat: @"%s:%@;", kKeyDateRecording, [Misc date2YYYY_MM_DD: NSDate.date]];
		[ergFileString appendFormat: @"%s:%@;", kKeyTimeRecording, [Misc date2HH_MM_SSdotted: NSDate.date]];

		[ergFileString appendFormat: @"\"\nX note %@, \";", ws];
		[ergFileString appendFormat: @"%s:%@;", kKeySubjectName, [[d objectForKey: @kKeySubjectName] description]];
		[ergFileString appendFormat: @"%s:%@;", kKeyDateBorn, [Misc date2YYYY_MM_DD: [d objectForKey: @kKeyDateBorn]]];
		[ergFileString appendFormat: @"%s:%d;", kKeySubjectPIZ, [[d objectForKey: @kKeySubjectPIZ] intValue]];
		[ergFileString appendFormat: @"%s:%g;", kKeyAcuityOD, [[d objectForKey: @kKeyAcuityOD] floatValue]];
		[ergFileString appendFormat: @"%s:%g;\"\n", kKeyAcuityOS, [[d objectForKey: @kKeyAcuityOS] floatValue]];

		[ergFileString appendFormat: @"X note %@, \";%s:%@;", ws, kKeyDoctor, [[d objectForKey: @kKeyDoctor] description]];
		[ergFileString appendFormat: @"%s:%@;", kKeyDiagnosis, [[d objectForKey: @kKeyDiagnosis] description]];
		[ergFileString appendFormat: @"%s:%@;\"\n", kKeyRemark, [[d objectForKey: @kKeyRemark] description]];

#ifdef versionTinaTsai
		[ergFileString appendFormat: @"X note %@, \";%s:%s;", ws, kKeyEyeKey, i==0 ? "OD" : "OU"]; // "OS" –> "OU"
		[ergFileString appendFormat: @"%s:%@;", kKeyEPKey, i==0 ? [[d objectForKey: @kKeyEPKey] description] : @"VEP"];	//  "VEP"
#else
		[ergFileString appendFormat: @"X note %@, \";%s:%s;", ws, kKeyEyeKey, i==0 ? "OD" : "OS"];
		[ergFileString appendFormat: @"%s:%@;", kKeyEPKey, [[d objectForKey: @kKeyEPKey] description]];
#endif
		[ergFileString appendString: @"nSweeps:1;"];

		[ergFileString appendFormat: @"\"\nX note %@, \";", ws];
		[ergFileString appendFormat: @"%s:%@;", kKeyStimName, [[d objectForKey: @kKeyStimName] description]];
		[ergFileString appendFormat: @"%s:%@;", kKeyStimNameISCEV, [[d objectForKey: @kKeyStimNameISCEV] description]];
		[ergFileString appendFormat: @"%s:%g;", kKeyFlashStrength, [[d objectForKey: @kKeyFlashStrength] floatValue]];
		[ergFileString appendFormat: @"%s:%@;", kKeyFlashColor, [[d objectForKey: @kKeyFlashColor] description]];
		[ergFileString appendFormat: @"%s:%g;", kKeyFlashDuration, [[d objectForKey: @kKeyFlashDuration] floatValue]];
		[ergFileString appendFormat: @"%s:%g;", kKeyFlashLuminance, [[d objectForKey: @kKeyFlashLuminance] floatValue]];
		[ergFileString appendFormat: @"%s:%g;", kKeyStimFrequency, [[d objectForKey: @kKeyStimFrequency] floatValue]];

		[ergFileString appendFormat: @"\"\nX note %@, \";", ws];
		[ergFileString appendFormat: @"%s:%g;", kKeyBackgroundLuminance, [[d objectForKey: @kKeyBackgroundLuminance] floatValue]];
		[ergFileString appendFormat: @"%s:%@;", kKeyBackgroundColor, [[d objectForKey: @kKeyBackgroundColor] description]];
		[ergFileString appendFormat: @"\"\n"];
	}	
	[ergFileString appendString: @"\n\n"];
	
	//BOOL result = [ergFileString writeToFile: [self pathToERGFileGivenEPNum: epNum] atomically:YES encoding:NSMacOSRomanStringEncoding error: NULL];
	NSString *path = [NSString stringWithString: [self pathToERGFileGivenEPNum: epNum]];
	BOOL result = [ergFileString writeToFile: path atomically:YES encoding:NSMacOSRomanStringEncoding error: NULL];
	if (!result)
		NSRunAlertPanel(@"Alert:", @"Recording could not be written to disk.", @"OK", NULL, NULL);

	// NSLog(@"saveTrace ENDE, hier %@", [self pathToERGFileGivenEPNum: epNum]);
}


@end
