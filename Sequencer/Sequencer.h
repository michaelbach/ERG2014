//
//  ERGsequencer.h
//  ERG2007
//
//  Created by bach on 25.11.08.
//  Copyright 2008 Prof. Michael Bach. All rights reserved.
//
//	History
//	=======
//
//	There are »sequences« which are in a given »stateInSequence« or "step".
//	For each step the stimulus is described by a dictionary of parameters: flash strength, color, background etc.
//	A sequence contains a number of states, through which we step while recording (weak flashes first etc.)
//	When "setting" a sequence, its state is always reset to the first state
//
//
//	2010-02-15	major change: the dictionary describing the stimulus is now read from a property list file
//	2009-12-30	added properties

#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "Misc.h"


@interface Sequencer : NSObject {
	NSMutableArray* allSequencesNames;
	NSMutableArray* allSequencesDicts;
	NSUInteger stateInSequence, selectedSequence;
}


- (NSUInteger) selectedSequence;
- (void) setSelectedSequence: (NSUInteger) seq;
- (NSUInteger) numberOfSequences;
- (NSString*) sequenceName;

@property NSUInteger stateInSequence;
- (NSUInteger) numberOfStates;

- (NSString*) stimName;
- (NSString*) stimNameISCEV4;
- (NSString*) stimDescription;
- (CGFloat) flashStrength;
- (CGFloat) flashFrequency;
- (NSString*) singleOrFlicker;
- (BOOL) isFlicker;
- (NSString*) flashColor;
- (CGFloat) backgroundLuminance;
- (CGFloat) backgroundLuminanceNextState;	// we need this so we can send a warning when we would loose adaptation
- (NSString*) backgroundColor;

- (NSString*) allSettingsString;


@end
