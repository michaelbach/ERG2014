//
//  WaveStats.mm
//  ERG2007
//
//  Created by bach on 26.01.07.
//  Copyright 2007 Prof. Michael Bach. All rights reserved.
//

#import "EDGWaveStats.h"


@implementation EDGWaveStats


- (id) init {	// NSLog(@"EDGWaveStats>init");
	return [self initWithNSArray: [NSArray array]];
}


- (void) evaluateCArray: (CGFloat*) inArray count: (NSUInteger) theCount {
	if (theCount>0) {
		V_npnts = 0;
		for (NSUInteger i=0; i<theCount; i++) {
			CGFloat f = inArray[i];
			if (V_npnts == 0) {	// 1st time
				V_minloc = 0;  V_maxloc = 0;  V_min=f;  V_max=f;  V_avg = 0.0;
			}
			if (f > V_max) {
				V_max = f;  V_maxloc = V_npnts;
			} else {
				if (f < V_min) {
					V_min = f;  V_minloc = V_npnts;
				}
			}
			V_avg += f;  V_npnts++;
		}
		V_avg /= V_npnts;  V_middle = V_min + (V_max-V_min)/2.0;  V_span = V_max-V_min;
	}	
}


- (id) initWithNSArray: (NSArray *) theArray {
	if ((self = super.init)) {	//	NSLog(@"EDGWaveStats>initWithMsg1");
		if (theArray.count == 0) return self;
		V_npnts = 0;
		for (NSNumber* aNumber in theArray) {
			CGFloat f = [aNumber floatValue];
			//	NSLog(@"%g", f);
			if (V_npnts == 0) {	// 1st time
				V_minloc = 0;  V_maxloc = 0;  V_min=f;  V_max=f;  V_avg = 0.0;
			}
			if (f > V_max) {
				V_max = f;  V_maxloc = V_npnts;
			} else {
				if (f < V_min) {
					V_min = f;  V_minloc = V_npnts;
				}
			}
			V_avg += f;  V_npnts++;
		}
		V_avg /= V_npnts;  V_middle = V_min + (V_max-V_min)/2.0;  V_span = V_max-V_min;
		//	NSLog(@"npnts:%d, min:%g, max:%g, avg:%g, span:%g", V_npnts, V_min, V_max, V_avg, V_span);			
	}
	return self;
}
- (id) initWithNSArray0: (NSArray *) theArray {
	if ((self = [super init])) {	//	NSLog(@"EDGWaveStats>initWithMsg1");
		if (theArray.count > 0) {
			NSEnumerator *enumerator = [theArray objectEnumerator];  id anObject;  
			V_npnts = 0;
			while ((anObject = [enumerator nextObject])) {
				CGFloat f = [anObject floatValue];
				//	NSLog(@"%g", f);
				if (V_npnts == 0) {	// 1st time
					V_minloc = 0;  V_maxloc = 0;  V_min=f;  V_max=f;  V_avg = 0.0;
				}
				if (f > V_max) {
					V_max = f;  V_maxloc = V_npnts;
				} else {
					if (f < V_min) {
					  	V_min = f;  V_minloc = V_npnts;
					}
				}
				V_avg += f;  V_npnts++;
			}
			V_avg /= V_npnts;  V_middle = V_min + (V_max-V_min)/2.0;  V_span = V_max-V_min;
			//	NSLog(@"npnts:%d, min:%g, max:%g, avg:%g, span:%g", V_npnts, V_min, V_max, V_avg, V_span);			
		}
	}
	return self;
}


- (double) min {return V_min;}

- (double) max {return V_max;}

- (double) avg {return V_avg;}

- (long) npnts {return V_npnts;}

- (double) span {return V_span;}

- (void) dealloc {	//	NSLog(@"EDGWaveStats>dealloc");
	[super dealloc];
}


@end
