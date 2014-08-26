//
//  ERGsequencer.m
//  ERG2007
//
//  Created by bach on 25.11.2008.
//  Copyright 2008 Prof. Michael Bach. All rights reserved.
//

#import "Sequencer.h"

@implementation Sequencer

- (id) init {
	if ((self = [super init])) {
		allSequencesNames = [[NSMutableArray arrayWithCapacity: 10] retain];
		allSequencesDicts = [[NSMutableArray arrayWithCapacity: 5] retain];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *appPath = [Misc pathOfApplicationContainer];
		NSMutableString *jumpAboveString = [NSMutableString stringWithCapacity: 20];
		NSMutableString *stimulusFolderPath;// = [NSMutableString stringWithCapacity: 50];
		BOOL found = NO;
		do {	// find the folder "ERG2007Stimuli" next to or upwards of this application
			stimulusFolderPath = [NSMutableString stringWithCapacity: 50];
			[stimulusFolderPath appendFormat: @"%@/%@%@", appPath, jumpAboveString, @"ERG2007Stimuli/"];
			found = [fileManager fileExistsAtPath: stimulusFolderPath];
			[jumpAboveString appendString: @"../"];
		} while ((!found) && (jumpAboveString.length < 3*8));	// allow maximal indirection of 5 folders
        if (!found) {
            stimulusFolderPath = [NSMutableString stringWithString: @"/Volumes/edg/KLINIK/ERG2007/ERG2007Stimuli/"];
            found = [fileManager fileExistsAtPath: stimulusFolderPath];
        }
		if (found) {	// we have found it, now look inside for *.plist files
			NSArray *folderContents = [NSArray arrayWithArray: [fileManager contentsOfDirectoryAtPath:stimulusFolderPath error: nil]];
			for (NSString *aFileName in folderContents) {
				if ([[aFileName pathExtension] isEqualToString: @"plist"]) {	// it's a plist file, so let's assume it is an array of stimulus dictionaries
					[allSequencesNames addObject: [aFileName stringByDeletingPathExtension]];	// name of the sequence derives from the filename
					// NSLog(@"%@", [aFileName stringByDeletingPathExtension]);
					[allSequencesDicts addObject: [NSArray arrayWithContentsOfFile: [stimulusFolderPath stringByAppendingPathComponent: aFileName]]]; // stim dict
					// NSLog(@"%@", [aFileName stringByDeletingPathExtension]);
				}
			}
		}

		if ([allSequencesNames count] <=0) {	// in case no stimulus file was found
			[allSequencesNames addObject: @"none"];
			[allSequencesDicts addObject: [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys:
				@"PHOTOPIC", @kKeyStimName, @"LightAdapted3.0", @kKeyStimNameISCEV, 
				[NSNumber numberWithFloat: 3], @kKeyFlashStrength, [NSNumber numberWithFloat: 1], @kKeyStimFrequency, @"W", @kKeyFlashColor,
				[NSNumber numberWithFloat: 10], @kKeyBackgroundLuminance,	@"B", @kKeyBackgroundColor,
				nil]]];
		}
		
		[self setSelectedSequence: 0];
		for (NSUInteger i = 0; i < allSequencesNames.count; ++i) {	// let's select the standard stimulus sequence
			if ([[allSequencesNames objectAtIndex: i] isEqualToString: @"ISCEV 2009"]) {
				//[self setSelectedSequence: i];
				break;
			}
		}
	}
	return self;
}

- (NSUInteger) numberOfSequences {
	return allSequencesNames.count;
}


- (NSUInteger) selectedSequence {
	return selectedSequence;
}
- (void) setSelectedSequence: (NSUInteger) seq {
	self.stateInSequence = 0;
	if (seq >= allSequencesDicts.count) return;
	selectedSequence = seq;  
}


- (NSString*) sequenceName {
	return [allSequencesNames objectAtIndex: selectedSequence];
}


- (NSString*) allSettingsString {
	NSUInteger oldState = [self stateInSequence];  NSMutableString* sequenceString = [NSMutableString stringWithCapacity: 500];
	for (NSUInteger iState=0; iState < self.numberOfStates; iState++) {
		self.stateInSequence = iState;
		[sequenceString appendFormat: @"%2u: ", iState+1];
		[sequenceString appendFormat: @"%@, ", [self stimName]];
		[sequenceString appendFormat: @"%@, ", [self stimNameISCEV4]];
		[sequenceString appendFormat: @"%@, ", [self stimDescription]];
		[sequenceString appendFormat: @"%g cd·s/m², ", [self flashStrength]];
		[sequenceString appendFormat: @"%g Hz, ", [self flashFrequency]];
		[sequenceString appendFormat: @"%@, ", [self singleOrFlicker]];
		[sequenceString appendFormat: @"fCol: %@, ", [self flashColor]];
		[sequenceString appendFormat: @"bLum: %g cd/m², ", [self backgroundLuminance]];
		[sequenceString appendFormat: @"bCol: %@.", [self backgroundColor]];
		if (iState+1<[self numberOfStates]) [sequenceString appendFormat: @"\r\r"];
	}
	self.stateInSequence = oldState;
	return sequenceString;
}


- (NSUInteger) numberOfStates { return [[allSequencesDicts objectAtIndex: selectedSequence] count]; }


- (NSObject*) object4key: (NSString *) key {
	NSObject *anObject = [[[allSequencesDicts objectAtIndex: selectedSequence] objectAtIndex: stateInSequence] objectForKey: key];
	if (anObject == nil) {
		//NSRunAlertPanel(@"A stimulus parameter is missing, key:", key, @"Ok", nil, nil);
        if ([key isEqualTo:@kKeySingleOrFlicker]) {
            anObject = (NSObject*)(self.flashFrequency < 3.0) ? @"single" : @"flicker";
        }
	}
	return anObject;
}

- (NSString*) stimName; {
	return [[self object4key: @kKeyStimName] description];
}


- (NSString*) stimNameISCEV4; {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	return [[self object4key: @kKeyStimNameISCEV] description];
}


- (NSString*) stimDescription; {	NSLog(@"%s", __PRETTY_FUNCTION__);
	return [[self object4key: @kKeyStimDescription] description];
}


- (CGFloat) flashStrength; {	//	NSLog(@"flashStrength");
	return [(NSNumber *)[self object4key: @kKeyFlashStrength] floatValue];
}


- (CGFloat) flashFrequency; {	//	NSLog(@"flashFrequency");
	return [(NSNumber *)[self object4key: @kKeyStimFrequency] floatValue];
}


- (NSString*) singleOrFlicker; {	//	NSLog(@"singleOrFlicker");
	return [[self object4key: @kKeySingleOrFlicker] description];
}


- (BOOL) isFlicker {
    return [self.singleOrFlicker isEqualTo:@"flicker"];
}


- (NSString*) flashColor; {	//	NSLog(@"flashColor");
	return [[self object4key: @kKeyFlashColor] description];
}


- (CGFloat) backgroundLuminance; {	//	NSLog(@"backgroundLuminance");
	CGFloat f = [(NSNumber *)[self object4key: @kKeyBackgroundLuminance] floatValue];
	return f;
}


- (CGFloat) backgroundLuminanceNextState {	//	NSLog(@"backgroundLuminanceNextState");
	if (stateInSequence < ([[allSequencesDicts objectAtIndex: selectedSequence] count] - 1)) {
		NSUInteger oldState = stateInSequence;
		++stateInSequence; CGFloat f = [self backgroundLuminance]; stateInSequence = oldState;
		return f;
	} else {
		return [self backgroundLuminance];
	}
}


- (NSString*) backgroundColor; {	//	NSLog(@"backgroundColor");
	return [[self object4key: @kKeyBackgroundColor] description];
}


@synthesize stateInSequence;


@end
