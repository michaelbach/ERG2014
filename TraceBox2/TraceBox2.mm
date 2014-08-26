//
//  TraceBox.m
//  ERG2007
//
//  Created by bach on 23.12.06.
//  Copyright 2006 Prof. Michael Bach. All rights reserved.
//

#import "TraceBox2.h"


@implementation TraceBox2


// local stuff first
- (void) setTraceColorFromIndex: (NSUInteger) theIndex {
	theIndex = theIndex % 7;
	switch (theIndex) {
		case 1: 
			_traceColor = [NSColor colorWithDeviceHue:0.25 saturation:1.0 brightness:0.5 alpha:1.0];		break;
		case 2: 	// dunkles Rot
			_traceColor = [NSColor colorWithDeviceHue:0.0 saturation:1.0 brightness:0.5 alpha:1.0];		break;
		case 3:		// dunkles Cyan
			_traceColor = [NSColor colorWithDeviceHue: 0.500 saturation: 1.0 brightness: 0.6 alpha: 1.0];		break;
		case 4: 	// dunkles Magenta
			_traceColor = [NSColor colorWithDeviceHue: 0.833 saturation: 1.0 brightness: 0.6 alpha: 1.0];	break;
		case 5: 	// dunkles Grün
			_traceColor = [NSColor colorWithDeviceHue: 0.125 saturation: 1.0 brightness: 0.6 alpha: 1.0];		break;
		default: _traceColor = [NSColor colorWithDeviceHue:0.667 saturation:1.0 brightness:0.6 alpha:1.0];	// dunkles Blau
	}
}
///////////////////////////////////////////////


- (id) initWithFrame: (NSRect) frame {	//	NSLog(@"TraceBox2>initWithFrame\n");
    self = [super initWithFrame:frame];
    if (self) {
		_traceColor = NSColor.blackColor;  _backgroundColor = NSColor.whiteColor;
		_numTraces = 0;  self.numTracesAverageThreshold = 5;  self.lineWidth = 2.0;  self.avarageScale = 3.0;
		CGFloat maxPositiveValue = 5.0;	// will later be overridden anyway
		_txy = [[WndwViewportXform alloc] initWithVprt: self.bounds andWndw: NSMakeRect(0, -maxPositiveValue, frame.size.width, maxPositiveValue*2.0)];
		runningAverage = [[NSMutableArray arrayWithCapacity:300] retain];
    }
    return self;
}


- (id) initWithFrame: (NSRect) frame andSuperView: (NSView *) sView {	//	NSLog(@"TraceBox2>initWithFrame andSuperView");
	self = [self initWithFrame: frame];
    if (self) [sView addSubview: self];
    return self;	
}

	
- (void) dealloc {	NSLog(@"TraceBox2>dealloc\n");
	[self removeFromSuperviewWithoutNeedingDisplay];
	for (NSUInteger iTrace=0; iTrace < _numTraces; iTrace++)  [bezierPaths[iTrace] release];
	[_traceColor release];  [_backgroundColor release];  [_txy release];  [bezierPathAverage release];
	[super dealloc];
}


- (void) setCoordsRange: (NSRect) theRect{
	[_txy setWndwRect: theRect];
}


- (void) drawRect: (NSRect) rect {	//	NSLog(@"TraceBox2>drawRect");
	if (bezierPaths[0] == NULL) return;
	[_backgroundColor set]; NSRectFill(rect);
	[NSBezierPath setDefaultLineWidth: 1.0]; 
    [[NSColor blackColor] set];
	[NSBezierPath strokeRect: rect];
	for (NSUInteger iTrace=0; iTrace < _numTraces; iTrace++) {
		if (_numTraces > numTracesAverageThreshold) {
			//[[NSColor lightGrayColor] set];  
			[[NSColor grayColor] set];  bezierPaths[iTrace].lineWidth = 0.5;
		} else {
			[self setTraceColorFromIndex: iTrace];  [_traceColor set];  bezierPaths[iTrace].lineWidth = lineWidth;
		}
		[bezierPaths[iTrace] stroke];
	}
	if (_numTraces > numTracesAverageThreshold) {
		if (bezierPathAverage != nil) [bezierPathAverage release];
		bezierPathAverage = [[NSBezierPath bezierPath] retain];
		[bezierPathAverage moveToPoint: [_txy user2device:NSMakePoint(0, [[runningAverage objectAtIndex: 0] floatValue]/_numTraces*avarageScale)]];
		for (NSUInteger i=1; i < runningAverage.count; i++)
			[bezierPathAverage  lineToPoint: [_txy user2device:NSMakePoint(i, [[runningAverage objectAtIndex:i] floatValue]/_numTraces*avarageScale)]];	
		[[NSColor blueColor] set];
		bezierPathAverage.lineWidth = lineWidth;  [bezierPathAverage stroke];
	}
	//	NSLog(@"TraceBox2>drawRect DONE");
}


- (void) addTrace: (NSArray *) theArray {	//	NSLog(@"TraceBox2>addTrace");
	if (_numTraces >= kMaxRepetitionsPerStimulus) return;
	if (_numTraces == 0)
		for (NSUInteger i=0; i<theArray.count; ++i) [runningAverage addObject: [NSNumber numberWithFloat: 0.0]]; 
	for (NSUInteger i=0; i<theArray.count; ++i) {
		CGFloat f = [[runningAverage objectAtIndex: i] floatValue];
		f += [[theArray objectAtIndex: i] floatValue];
		[runningAverage replaceObjectAtIndex: i withObject: [NSNumber numberWithFloat: f]];
	}
	bezierPaths[_numTraces] = [[NSBezierPath bezierPath] retain];
	[bezierPaths[_numTraces] moveToPoint: [_txy user2device:NSMakePoint(0, [[theArray objectAtIndex:0] floatValue])]];
	for (NSUInteger i=1; i <  theArray.count; i++)  [bezierPaths[_numTraces]  lineToPoint: [_txy user2device:NSMakePoint(i, [[theArray objectAtIndex:i] floatValue])]];	
	_numTraces++;
	[self setNeedsDisplay:YES];	
}



- (void) forgetLastTrace {
	if (_numTraces <= 0) return;
	_numTraces--;  [bezierPaths[_numTraces + 1] release];	
	[self setNeedsDisplay:YES];	
}


- (CGFloat) width {
	return self.frame.size.width;
}
- (CGFloat) height {
	return self.frame.size.height;
}


@synthesize lineWidth;
@synthesize avarageScale;
@synthesize numTracesAverageThreshold;


- (void) addTestTrace {
	NSUInteger numPnts = round(self.width);
	CGFloat prev = 0.0;
	if (numPnts <2) return;
	NSMutableArray *voltages = [NSMutableArray arrayWithCapacity: numPnts];
	for (NSUInteger iPnt = 0; iPnt < numPnts; ++iPnt) {
		CGFloat rVoltage = 0.5 * (2.0 * random() / (CGFloat)RAND_MAX - 1.0) * self.height;
		[voltages addObject: [NSNumber numberWithFloat: (rVoltage + 9 * prev)/10.0]];
	}
	[self addTrace: voltages];
}

@end

