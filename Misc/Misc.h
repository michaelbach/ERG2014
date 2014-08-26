//
//  Misc.h
//  ERG2007
//
//  Created by bach on 15.02.10.
//  Copyright 2010 Universitäts-Augenklinik. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Misc : NSObject {


}

+ (NSString *) pathOfApplicationContainer;
+ (NSString *) date2YYYY_MM_DD: (NSDate *) theDate;
+ (NSString *) date2HH_MM_SS: (NSDate *) theDate;
+ (NSString *) date2HH_MM_SSdotted: (NSDate *) theDate;
+ (NSString *) epNum2fullString: (NSUInteger) epNum;
+ (NSString *) string2MacOSRomanLossy: (NSString*) inString;

@end
