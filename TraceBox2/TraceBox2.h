/*  TraceBox2.h for ERG2007

Created by bach on 23.12.06.
Copyright 2006 Prof. Michael Bach. All rights reserved.
 
This class puts a box into a superview (e.g. window content) where traces can be added. Colors are automatically chosen. 
The user coordinates are transformed to screen coordinates using the standard window/viewport nomenclature.
The Viewport is the view rectangle, the window coordinates are set via "setCoordsRange"
If more than "numTracesAverageThreshold" (default : 5) are added, the single traces are plotted in gray and an average is added.

History
=======

2010-05-26	made averaging more flexible
2010-05-25	added option to average
2010-05-25	added "removeFromSuperviewWithoutNeedingDisplay" in dealloc
2010-05-24	TraceBox2: programmatically created
2010-02-23	darker trace colors, tryal with lineWidth=2
*/


#import <Cocoa/Cocoa.h>
#import "WndwViewportXform.h"


#import "Globals.h"
//#define kMaxRepetitionsPerStimulus 10


@interface TraceBox2 : NSView {
	NSUInteger _numTraces, numTracesAverageThreshold;
	NSBezierPath *bezierPaths[kMaxRepetitionsPerStimulus], *bezierPathAverage;
	NSMutableArray *runningAverage;
	NSColor *_traceColor, *_backgroundColor;
	WndwViewportXform *_txy;
	CGFloat lineWidth, avarageScale;
}


- (id) initWithFrame: (NSRect) frame andSuperView: (NSView *) sView;
- (CGFloat) width;							// view(port) dimensions
- (CGFloat) height;							// view(port) dimensions
- (void) addTestTrace;						// adds trace of random numbers for testing
- (void) addTrace: (NSArray *) theArray;
- (void) forgetLastTrace;
- (void) setCoordsRange: (NSRect) theRect;	// user coordinate system (window)
@property CGFloat avarageScale;				// averages are scaled up, default is 3.0
@property CGFloat lineWidth;
@property NSUInteger numTracesAverageThreshold; // switchover from single traces to average

@end
