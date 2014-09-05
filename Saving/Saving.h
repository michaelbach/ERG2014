//
//  Saving.h
//  ERG2007
//
//  Created by bach on 07.01.07.
//  Copyright 2007 Prof. Michael Bach. All rights reserved.
//
//	History
//	=======
//

#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "Misc.h"


@interface Saving : NSObject {
    CGFloat amplificationFactor, acuityOD, acuityOS, flashStrength, flashDuration, flashLuminance, stimFrequency, backgroundLuminance;
    NSInteger epNumber, stimNumber, blockNumber;
    NSString *subjectNameString, *subjectPIZString, *referrerString, *diagnosisString, *remarkString, *stimNameString, *stimNameISCEVString, *flashLEDColorString, *backgroundColorString;
    NSDate *dateBorn;
    BOOL isHardwareOK;
}

- (void) saveTracesOD: (NSArray *) traceOD andOS: (NSArray *) traceOS andFlash: (NSArray *) traceFlash;

@property (assign) BOOL isHardwareOK;
@property (assign) CGFloat amplificationFactor;
@property (assign) CGFloat acuityOD;
@property (assign) CGFloat acuityOS;
@property (assign) CGFloat flashStrength;
@property (assign) CGFloat flashDuration;
@property (assign) CGFloat flashLuminance;
@property (assign) CGFloat stimFrequency;
@property (assign) CGFloat backgroundLuminance;
@property (assign) NSInteger epNumber;
@property (assign) NSInteger stimNumber;
@property (assign) NSInteger blockNumber;
@property (assign) NSString *subjectNameString;
@property (assign) NSString *subjectPIZString;
@property (assign) NSString *referrerString;
@property (assign) NSString *diagnosisString;
@property (assign) NSString *remarkString;
@property (assign) NSString *stimNameString;
@property (assign) NSString *stimNameISCEVString;
@property (assign) NSString *flashLEDColorString;
@property (assign) NSString *backgroundColorString;
@property (assign) NSDate *dateBorn;


@end
