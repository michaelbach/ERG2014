//
//  EDGWaveStats.h
//  ERG2007
//
//  Created by bach on 26.01.07.
//  Copyright 2007 Prof. Michael Bach. All rights reserved.
//
//	History
//	=======
//

#import <Cocoa/Cocoa.h>


@interface EDGWaveStats : NSObject {

	long V_npnts;		//	Number of points. Doesn't include NaN or INF points.
//	long V_numNans;		//	Number of NaNs.
//	V_numINFs	Number of INFs.
	double	V_avg;		//	Average of Y values.
//	V_sdev;		//	Standard deviation of Y values, 
//	V_rms;		//	RMS of Y values 
//	V_adev;		//	Average deviation 
//	V_skew	Skewness 
//	V_kurt	Kurtosis 
	long	V_minloc;	//	X location of minimum Y value.
	double	V_min;		//	Minimum Y value.
	long	V_maxloc;	//	X location of maximum Y value.
	double	V_max;		//	Maximum Y value
	double	V_middle;	//	min+(max-min)/2
	double	V_span;		//	max-min
}


- (id) initWithNSArray: (NSArray *) theArray;
- (void) evaluateCArray: (CGFloat*) inArray count: (NSUInteger) theCount;
- (double) min;
- (double) max;
- (double) avg;
- (long) npnts;
- (double) span;


@end
