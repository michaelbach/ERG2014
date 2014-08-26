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
}

- (void) saveTracesOD: (NSArray *) traceOD andOS: (NSArray *) traceOS andFlash: (NSArray *) traceFlash andDict: (NSDictionary *) dict;

- (void) test1id: (id) owner;
	
@end
