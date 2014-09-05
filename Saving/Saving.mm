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

@synthesize isHardwareOK;
@synthesize amplificationFactor;
@synthesize acuityOD;
@synthesize acuityOS;
@synthesize flashStrength;
@synthesize flashDuration;
@synthesize flashLuminance;
@synthesize stimFrequency;
@synthesize backgroundLuminance;
@synthesize epNumber;
@synthesize stimNumber;
@synthesize blockNumber;

@synthesize subjectNameString;
@synthesize subjectPIZString;
@synthesize referrerString;
@synthesize diagnosisString;
@synthesize remarkString;
@synthesize stimNameString;
@synthesize stimNameISCEVString;
@synthesize flashLEDColorString;
@synthesize backgroundColorString;
@synthesize dateBorn;


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
        subjectNameString = @"";
        subjectPIZString = @"";
        referrerString = @"";
        diagnosisString = @"";
        remarkString = @"";
	}
	return self;
}


- (void) dealloc {	//	NSLog(@"ERG2007>Saving>dealloc\n");
    [[NSNotificationCenter defaultCenter] removeObserver: self];
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


- (void) saveTracesOD: (NSArray *) tOD andOS: (NSArray *) tOS andFlash: (NSArray *) tFlash {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	// if hardware is missing, we are in demo mode, and can't detect the flash time anyway.
	CGFloat timeOfFlash = isHardwareOK ? [self detectFlashTime: tFlash] : 0;
	//	NSLog(@"timeOfFlash: %d", (NSInteger)timeOfFlash);
	
	NSMutableString *ergFileString = [NSMutableString stringWithContentsOfFile: [self pathToERGFileGivenEPNum: epNumber] encoding:NSMacOSRomanStringEncoding error: NULL];
	if (ergFileString.length <1) {
		ergFileString = [NSMutableString stringWithCapacity: 10000]; [ergFileString appendString: @"IGOR\n"];
	}
	NSString *waveOD, *waveOS, *waveFlash;
	waveOD = [self composeWaveNameFromBlockNum: blockNumber andStimNum: stimNumber andChannel: 0];
	waveOS = [self composeWaveNameFromBlockNum: blockNumber andStimNum: stimNumber andChannel: 1];
	waveFlash = [self composeWaveNameFromBlockNum: blockNumber andStimNum: stimNumber andChannel: 2];
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
		[ergFileString appendFormat: @"%s:%ld;", kKeyEPNumber, (long)epNumber];
		[ergFileString appendFormat: @"%s:%ld;", kKeyBlockNumber, (long)blockNumber];
		[ergFileString appendFormat: @"%s:%ld;", kKeyStimNumber, (long)stimNumber];
		[ergFileString appendFormat: @"%s:%lu;", kKeyChannel, (unsigned long)i];
		[ergFileString appendFormat: @"%s:%@;", kKeyDateRecording, [Misc date2YYYY_MM_DD: NSDate.date]];
		[ergFileString appendFormat: @"%s:%@;", kKeyTimeRecording, [Misc date2HH_MM_SSdotted: NSDate.date]];

		[ergFileString appendFormat: @"\"\nX note %@, \";", ws];
		[ergFileString appendFormat: @"%s:%@;", kKeySubjectName, subjectNameString];
		[ergFileString appendFormat: @"%s:%@;", kKeyDateBorn, [Misc date2YYYY_MM_DD: dateBorn]];
		[ergFileString appendFormat: @"%s:%@;", kKeySubjectPIZ, subjectPIZString];
		[ergFileString appendFormat: @"%s:%g;", kKeyAcuityOD, acuityOD];
		[ergFileString appendFormat: @"%s:%g;", kKeyAcuityOS, acuityOS];
		[ergFileString appendString: @"\"\n"];

		[ergFileString appendFormat: @"X note %@, \";%s:%@;", ws, kKeyDoctor, referrerString];
		[ergFileString appendFormat: @"%s:%@;", kKeyDiagnosis, diagnosisString];
		[ergFileString appendFormat: @"%s:%@;\"\n", kKeyRemark, remarkString];

#ifdef versionTinaTsai
		[ergFileString appendFormat: @"X note %@, \";%s:%s;", ws, kKeyEyeKey, i==0 ? "OD" : "OU"]; // "OS" –> "OU"
		[ergFileString appendFormat: @"%s:%@;", kKeyEPKey, @"VEP"];
#else
		[ergFileString appendFormat: @"X note %@, \";%s:%s;", ws, kKeyEyeKey, i==0 ? "OD" : "OS"];
		[ergFileString appendFormat: @"%s:%@;", kKeyEPKey, @"ERG"];
#endif
		[ergFileString appendString: @"nSweeps:1;"];

		[ergFileString appendFormat: @"\"\nX note %@, \";", ws];
		[ergFileString appendFormat: @"%s:%@;", kKeyStimName, stimNameString];
		[ergFileString appendFormat: @"%s:%@;", kKeyStimNameISCEV, stimNameISCEVString];
		[ergFileString appendFormat: @"%s:%g;", kKeyFlashStrength, flashStrength];
		[ergFileString appendFormat: @"%s:%@;", kKeyFlashColor, flashLEDColorString];
		[ergFileString appendFormat: @"%s:%g;", kKeyFlashDuration, flashDuration];
		[ergFileString appendFormat: @"%s:%g;", kKeyFlashLuminance, flashLuminance];
		[ergFileString appendFormat: @"%s:%g;", kKeyStimFrequency, stimFrequency];

		[ergFileString appendFormat: @"\"\nX note %@, \";", ws];
		[ergFileString appendFormat: @"%s:%g;", kKeyBackgroundLuminance, backgroundLuminance];
		[ergFileString appendFormat: @"%s:%@;", kKeyBackgroundColor, backgroundColorString];
		[ergFileString appendFormat: @"\"\n"];
	}	
	[ergFileString appendString: @"\n\n"];
	
	//BOOL result = [ergFileString writeToFile: [self pathToERGFileGivenEPNum: epNum] atomically:YES encoding:NSMacOSRomanStringEncoding error: NULL];
	NSString *path = [NSString stringWithString: [self pathToERGFileGivenEPNum: epNumber]];
	BOOL result = [ergFileString writeToFile: path atomically:YES encoding:NSMacOSRomanStringEncoding error: NULL];
	if (!result)
		NSRunAlertPanel(@"Alert:", @"Recording could not be written to disk.", @"OK", NULL, NULL);

	// NSLog(@"saveTrace ENDE, hier %@", [self pathToERGFileGivenEPNum: epNum]);
}


@end
