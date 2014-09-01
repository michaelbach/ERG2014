#import "MainController.h"

@implementation MainController

@synthesize epNum;
@synthesize autoRecordRepeatCount;
@synthesize ergRepeatCount;


NSTimer *timer100Hz, *timerUntilExitMeasurement, *timerWaitNoOsci,
        *timerAutoRecordStart, *timerAutoRecordSave, *timerAutoRecordDone;
NSUInteger autoRepeatCounterAtStart;


///// first the fully private methods
/////////////////////////////////


- (void) dealloc {	// WHY IS THIS NOT ALWAYS CALLED? --> only when [self release] is called in "willTerminate"
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter; [nc removeObserver:self];
	[super dealloc];
}

- (id) init {   //NSLog(@"%s", __PRETTY_FUNCTION__);
	self = [super init];
	if (self != nil) {	//NSLog(@"%s", __PRETTY_FUNCTION__);
		prefsController = [[[PrefsController alloc] init] retain];
		[self setAutoHideOtherApplications: prefsController.autoHideOtherApplications];
	}
	return self;
}


- (void) textChanged: (NSNotification*) notification {	//	NSLog(@"textDidChange");
	NSTextField *field = notification.object;
	field.stringValue  = [Misc string2MacOSRomanLossy: field.stringValue];
}


- (void) handle100HzTimer: (NSTimer *) timer {
	static NSInteger timOld;
	if (isDoingSweepAcquisition)  return;
	in100Handler = YES;
	[osci advanceWithSamples: [ergAmplifier voltageAtChannels0to: 2]];
	in100Handler = NO;
	NSInteger tim = (NSInteger) round(-[ergTime timeIntervalSinceNow]);
	if (tim != timOld) {
		timOld = tim;  fieldTimeDisplay.stringValue = [NSString stringWithFormat: @"%02d:%02d", tim / 60, tim % 60];
	}
}


#pragma mark awake + init
- (void) awakeFromNib {	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp setDelegate: self];
    [self setMenuBarVisible: prefsController.menuBarVisible];

    camera = [[Camera2 alloc] initWithView: mCaptureView];//	let's deal with the camera if found

	[self setAutoStateAndButtons: NO];
	
	ergSequencer = [[Sequencer alloc] init];
	NSUInteger oldselectedSequence = ergSequencer.selectedSequence;
	for (NSUInteger i=0; i < ergSequencer.numberOfSequences; i++) {
		ergSequencer.selectedSequence = i;  [popupSequence_outlet addItemWithTitle: ergSequencer.sequenceName];
	}
	ergSequencer.selectedSequence = oldselectedSequence;  [popupSequence_outlet selectItemAtIndex: ergSequencer.selectedSequence];
	
	ergSaving = [[Saving alloc] init];

	isDoingSweepAcquisition = NO;  doesRecordingNeedSaving = NO;

	window = self.window;
	window.backgroundColor = [NSColor colorWithDeviceWhite: (CGFloat)0.25 alpha: 1];
	window.aspectRatio = window.frame.size;
	window.title = [NSString stringWithFormat: @"ERG2007  (vs %s)", kCurrentVersionDate];
	[window setFrameTopLeftPoint: NSMakePoint(0, 9999)]; // make sure it's top left (9999 will be clipped)// doing it earlier doesn't work
	[self buttonsAllDisable];
	[self showWindow: nil];
    [window makeKeyAndOrderFront: self];
    
	EDGInfoPanel *infoPanel = [[EDGInfoPanel alloc] initWithMsg1: [NSString stringWithUTF8String: "Initialising amplifier…"] andMsg2: NULL];
    ergAmplifier = [[RCAmpNI alloc] init];
	[infoPanel close];
    if (!ergAmplifier.isHardwareOk) {
        NSInteger result = NSRunAlertPanel(@"Problem initialising NIDAQ.", @"Ok?", @"OK", @"Cancel", NULL);
		if (result != NSAlertDefaultReturn)	[NSApp terminate:nil];
    }

	[osci setNumberOfTraces: 3];
	[osci setFullscale: 0.74 * [ergAmplifier maxVoltage]];
	[osci setColor: [NSColor colorWithDeviceRed:0 green:0 blue:0.5 alpha: 1] forTrace: 0];
	[osci setColor: [NSColor colorWithDeviceRed:0.5 green:0 blue:0.0 alpha: 1] forTrace: 1];
	[osci setColor: NSColor.darkGrayColor forTrace: 2];
	[osci setBackgroundColor: NSColor.lightGrayColor];
    [osci setIsShiftTraces: NO];
	
	traceOD = [[NSArray array] retain];  traceOS = [[NSArray array] retain];  traceTrigger = [[NSArray array] retain];
	recInfoDict = [[NSMutableDictionary dictionaryWithCapacity: 20] retain];
	
	infoPanel = [[EDGInfoPanel alloc] initWithMsg1: [NSString stringWithUTF8String: "Initialising stimulator…"] andMsg2: NULL];
	ergStimulator = [[Q450Stim alloc] init];  
	[ergStimulator setInfraredIllumination: YES];  [checkboxInfraredOn_outlet setState:([ergStimulator infraredIllumination] ? 1 : 0)];
	[infoPanel close];

	[self setERGNumberFromPreviousSession];
	
	infoPanel = [[EDGInfoPanel alloc] initWithMsg1: [NSString stringWithUTF8String: "Finalising initialisation…"] andMsg2: NULL];
	self.ergState = 0; // also opens amplifier
    [ergAmplifier closeAllChannels];  [self setAmpInputButtonTitle];

	[self buttonsStandardEnabledState];
    referrerNames = [[ReferrerNames alloc] init];
	[infoPanel close];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textChanged:) name: NSControlTextDidEndEditingNotification object: fieldSubjectName];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textChanged:) name: NSControlTextDidEndEditingNotification object: fieldReferrer];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textChanged:) name: NSControlTextDidEndEditingNotification object: fieldDiagnosis];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(textChanged:) name: NSControlTextDidEndEditingNotification object: fieldRemark];
	
	traceBoxesOD = [[NSMutableArray arrayWithCapacity: 30] retain];  traceBoxesOS = [[NSMutableArray arrayWithCapacity: 30] retain];
	for (NSUInteger i=0; i<30; ++i) {
		[traceBoxesOD addObject: @"notInitialised"];  [traceBoxesOS addObject: @"notInitialised"];
	}
    [self setAutoRecordRepeatCount: 5]; // should better be read from the stimuli plist
    
	in100Handler = NO;  ergTime = [[NSDate date] retain];
	timer100Hz = [[NSTimer scheduledTimerWithTimeInterval: kSampleIntervalOscilloscopeInS target: self selector: @selector(handle100HzTimer:) userInfo: nil repeats: YES] retain];
    
#ifdef versionAnimal
    [buttonRetrievePIZ_outlet setEnabled: NO];
    [fieldReferrer setEnabled: NO];
#endif
    
    [window makeKeyAndOrderFront: self];
    [window makeFirstResponder: fieldSubjectName];
    [fieldSubjectName becomeFirstResponder];
    [fieldSubjectName setFocusRingType:NSFocusRingTypeDefault];

	//[self setErgState: 10];	// this can help to speed up testing
	//NSLog(@"%s exit", __PRETTY_FUNCTION__);
}


#pragma mark Combo box data source methods BEGIN ============================
- (NSUInteger)numberOfItemsInComboBox: (NSComboBox *)aComboBox {
    return [referrerNames numberOfItemsInComboBox];
}
- (id)comboBox: (NSComboBox *)aComboBox objectValueForItemAtIndex: (NSUInteger) theIndex {
	return [referrerNames objectValueForItemAtIndex: theIndex];
}
- (NSUInteger)comboBox: (NSComboBox *)aComboBox indexOfItemWithStringValue: (NSString *)string {
    return [referrerNames indexOfItemWithStringValue: string];
}
- (NSString *)comboBox: (NSComboBox *)aComboBox completedString: (NSString *)inputString {
    return [referrerNames completedString: inputString];
}
#pragma mark Combo box data source methods END ============================


// NSWindow delegate
- (void)windowWillClose: (NSNotification *)notification; {	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[camera stopAndClose];	// lets not do it because it crashes the app (error in macam driver) 2009-06-10
}


- (void) setAmplifierConsideringStateWithOpen: (BOOL) openYesNo {
    [ergAmplifier setAmplificationFactorStandardERG: [prefsController amplificationFactor]];

#ifdef versionEDIAG
	[ergAmplifier setAmplifierToERGStandardAndOpen: openYesNo forScotopicNotPhotopic: [ergSequencer backgroundLuminance] < 2];
#endif

#ifdef versionTinaTsai
	[ergAmplifier setAmplifierToERGVEPStandardAndOpen: openYesNo];
#endif

#ifdef versionAnimal
    // only do this once, so the input is not closed and opened. Also we want the same filter settings throughout
    if (ergState < 1) {
        [ergAmplifier setAmplifierToERGStandardAndOpen: openYesNo forScotopicNotPhotopic: YES];
    }
#endif
    [self setAmpInputButtonTitle];
}


- (void) setERGNumberFromPreviousSession {	//NSLog(@"%s", __PRETTY_FUNCTION__);
    [self setEpNum: ([prefsController epNumber]+1)];
}


- (NSUInteger) ergState {return ergSequencer.stateInSequence;}
- (void) setErgState: (NSUInteger) newState { //NSLog(@"%s", __PRETTY_FUNCTION__);
	if (newState >= ergSequencer.numberOfStates) return;
	if (ergSequencer.backgroundLuminanceNextState > ergSequencer.backgroundLuminance) {
		NSInteger result = NSRunAlertPanel(@"The background will become brighter now.", @"Ok? (cancel will allow a repeat)", @"OK", @"Cancel", NULL);
		if (result == NSAlertAlternateReturn) {
			return;
		}
	}
	ergSequencer.stateInSequence = newState;  self.ergRepeatCount = 1;
	fieldStimNameISCEV.stringValue = ergSequencer.stimNameISCEV4;
	
	[ergStimulator setFlashLEDColorFromWGOKBR: ergSequencer.flashColor];	fieldFlashColor.stringValue = ergStimulator.flashLEDColor; // must be BEFORE strength!!!
	ergStimulator.flashStrength = ergSequencer.flashStrength;  [fieldFlashStrength setStringValue: [NSString localizedStringWithFormat: @"%g", [ergStimulator flashStrength]]];
	fieldFlashFreq.stringValue = [NSString localizedStringWithFormat: @"%g", ergSequencer.flashFrequency];

	ergStimulator.backgroundInCdPerMetersquare = ergSequencer.backgroundLuminance;  fieldBackgroundLum.floatValue = ergStimulator.backgroundInCdPerMetersquare;
	[ergStimulator setFixLEDIntensityHigh: ergStimulator.backgroundInCdPerMetersquare > 2];	// not necessary in Q450 but doesn't hurt
	[ergStimulator setBackgroundColorFromWGOKBR: ergSequencer.backgroundColor];  fieldBackgroundColor.stringValue = ergStimulator.backgroundColor;
	
	[self setAmplifierConsideringStateWithOpen: YES];
}


- (void) buttonsAllDisable {
	[buttonRecord_outlet setEnabled: NO]; [buttonKeepAndNext_outlet setEnabled: NO]; [buttonKeepAndAgain_outlet setEnabled: NO];  [buttonForget_outlet setEnabled: NO]; }
- (void) buttonsStandardEnabledState {
	[buttonRecord_outlet setEnabled: YES]; [buttonKeepAndNext_outlet setEnabled: NO]; [buttonKeepAndAgain_outlet setEnabled: NO]; [buttonForget_outlet setEnabled: NO]; 
	[ergStimulator setFixLED: q450FixLEDCenter];
}


#pragma mark Measurement
- (void) handleTimerWaitNoOsci: (NSTimer *) timer {
    [self initMeasurement];
}
- (void) initMeasurement {	//  NSLog(@"%s", __PRETTY_FUNCTION__);
	if (in100Handler) {
        [timerWaitNoOsci release];
        NSLog(@"wait in initMeasurement (timered)");
            timerWaitNoOsci = [[NSTimer scheduledTimerWithTimeInterval: 0.001 target: self selector: @selector(handleTimerWaitNoOsci:) userInfo: nil repeats: NO] retain];
        return;
    }
	isDoingSweepAcquisition = YES;	// tell the oscilloscope to pause
	[popupSequence_outlet setEnabled: NO];  [buttonRecord_outlet setEnabled: NO];	// no further actions like this
	[ergTime release];  ergTime = [[NSDate date] retain];	// time the start
	CGFloat flashFreq = ergSequencer.flashFrequency;
	NSUInteger sweepLengthInMs = ergSequencer.isFlicker ? kLengthFlickerTraceInMs : kLengthNonflickerTraceInMs;
	[ergAmplifier startSweepWithSamplingInterval: (NSInteger) round(kSampleIntervalERGInMs*1000.0) forNumChannels: 3 forSamplesPerChannel: sweepLengthInMs];
	timerFlicker = nil;
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.049, false);	// delay for pre-stimulus recording
	if (!ergSequencer.isFlicker) {	// single flash, no repetitive stimulation
		timerUntilExitMeasurement = [[NSTimer scheduledTimerWithTimeInterval: ((sweepLengthInMs+40)/1000.0) target: self selector: @selector(exitMeasurement:) userInfo: nil repeats: NO] retain];
		[ergStimulator doFlash];
	} else {	// repetitive stimulation (= flicker)
		timerFlicker = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
		__block NSInteger nFlashes = 2 + (NSInteger) round(kLengthFlickerTraceInMs / 1000.0 * flashFreq);
		dispatch_source_set_timer(timerFlicker, dispatch_time(DISPATCH_TIME_NOW, 0), /*interv*/ (int64_t) (1E9 / flashFreq), /*leeway*/ 0ull);
		dispatch_source_set_event_handler(timerFlicker, ^{
			if (--nFlashes > 0) {
				[ergStimulator doFlash];
			} else {
				dispatch_source_cancel(timerFlicker);
			}
		}); 
		dispatch_resume(timerFlicker);
		timerUntilExitMeasurement = [[NSTimer scheduledTimerWithTimeInterval: 0.2 + nFlashes/flashFreq target: self selector: @selector(exitMeasurement:) userInfo: nil repeats: NO] retain];
	}
}


- (void) exitMeasurement: (NSTimer *) timer {   //  NSLog(@"%s", __PRETTY_FUNCTION__);
	if (timerFlicker != nil) {	// make sure the dispatch timer is stopped
		dispatch_source_cancel(timerFlicker);  dispatch_release(timerFlicker);  timerFlicker = nil;
	}
	isDoingSweepAcquisition = NO;  doesRecordingNeedSaving = YES;
	traceOD = [ergAmplifier getSweepOfChannel: 1];  traceOS = [ergAmplifier getSweepOfChannel: 2];  traceTrigger = [ergAmplifier getSweepOfChannel: 0];
	[buttonRecord_outlet setEnabled: NO];  [buttonKeepAndNext_outlet setEnabled: !(([ergSequencer stateInSequence]+1) >= ([ergSequencer numberOfStates]))];  //NSLog(@"gSequenceStep: %d", gSequenceStep);
	[buttonKeepAndAgain_outlet setEnabled: (ergRepeatCount < (NSUInteger) kMaxRepetitionsPerStimulus)];
    [buttonForget_outlet setEnabled: !_isInAutoMode];
	CGFloat maxValueInTraceBox = [ergAmplifier maxVoltage]/3.0;// 3.0 was 2.0 2014-08-28 mb
	NSRect coordRect = NSMakeRect(0, -maxValueInTraceBox, ergSequencer.isFlicker ? kLengthFlickerTraceInMs : kLengthNonflickerTraceInMs, 2*maxValueInTraceBox);
	[self tellTracebox: [self getTraceBoxOfState: ergSequencer.stateInSequence andEye: OD] setCoords: coordRect andAddTrace: traceOD];
	[self tellTracebox: [self getTraceBoxOfState: ergSequencer.stateInSequence andEye: OS] setCoords: coordRect andAddTrace: traceOS];
	[ergStimulator setFixLED: q450FixLEDNone];
    [traceOD retain];  [traceOS retain];  [traceTrigger retain];    // if I don't retain here, the instances are gone when trying to save 2013-11-22
}


#pragma mark Traceboxes
- (TraceBox2 *) getTraceBoxOfState: (NSUInteger) theState andEye: (EyeCode) theEye {
	if (theState >= [ergSequencer numberOfStates]) return nil;
	if ([[traceBoxesOD objectAtIndex:theState] isEqual: @"notInitialised"]) {
		CGFloat top = 898.0, xOD = 510, xOS = 799, ww = 286, hh = (top-16) / [ergSequencer numberOfStates];
		[traceBoxesOD insertObject: [[TraceBox2 alloc] initWithFrame: NSMakeRect(xOD, top-hh*(theState+1), ww, hh) andSuperView: [window contentView]] atIndex:theState];
		[traceBoxesOS insertObject: [[TraceBox2 alloc] initWithFrame:NSMakeRect(xOS, top-hh*(theState+1), ww, hh)andSuperView: [window contentView]] atIndex:theState];
	}
	return (theEye == OD) ? [traceBoxesOD objectAtIndex: theState] : [traceBoxesOS objectAtIndex: theState];
}
- (void) tellTracebox: (TraceBox2 *) tracebox setCoords: (NSRect) coordRect andAddTrace: (NSArray *) trace {
	[tracebox setCoordsRange: coordRect];  tracebox.lineWidth = 1.5;  [tracebox addTrace: trace];
}


# pragma mark Saving
- (void) saveMeasurement {	//NSLog(@"%s", __PRETTY_FUNCTION__);
	if (!doesRecordingNeedSaving) return;
	
	[recInfoDict setObject: [NSNumber numberWithInt: epNum] forKey: @kKeyEPNumber];
	[recInfoDict setObject: @"ERG" forKey: @kKeyEPKey];
	[recInfoDict setObject: [NSNumber numberWithInt: ergSequencer.stateInSequence] forKey: @kKeyStimNumber];
	[recInfoDict setObject: [NSNumber numberWithInt: ergRepeatCount - 1] forKey: @kKeyBlockNumber];
	[recInfoDict setObject: fieldSubjectName.stringValue forKey: @kKeySubjectName];
	[recInfoDict setObject: fieldSubjectPIZ.stringValue forKey: @kKeySubjectPIZ];
	[recInfoDict setObject: dateFieldBirthDate.dateValue forKey: @kKeyDateBorn];
	[recInfoDict setObject: [NSNumber numberWithFloat: fieldAcuityOD.floatValue] forKey: @kKeyAcuityOD];
	[recInfoDict setObject: [NSNumber numberWithFloat: fieldAcuityOS.floatValue] forKey: @kKeyAcuityOS];
	[recInfoDict setObject: fieldReferrer.stringValue forKey: @kKeyDoctor];
	[recInfoDict setObject: fieldDiagnosis.stringValue forKey: @kKeyDiagnosis];
	[recInfoDict setObject: fieldRemark.stringValue forKey: @kKeyRemark];
	[recInfoDict setObject: [NSString stringWithString: ergSequencer.stimName] forKey: @kKeyStimName];
	[recInfoDict setObject: [NSString stringWithString: ergSequencer.stimNameISCEV4] forKey: @kKeyStimNameISCEV];
	[recInfoDict setObject: [NSNumber numberWithFloat: ergStimulator.flashStrength] forKey: @kKeyFlashStrength];
	[recInfoDict setObject: ergStimulator.flashLEDColor forKey: @kKeyFlashColor];
	[recInfoDict setObject: [NSNumber numberWithFloat: ergStimulator.flashLEDDurationInSecs] forKey: @kKeyFlashDuration];
	[recInfoDict setObject: [NSNumber numberWithFloat: ergStimulator.flashLEDLuminanceInCdPerMetersquare] forKey: @kKeyFlashLuminance];
	[recInfoDict setObject: [NSNumber numberWithFloat: ergSequencer.flashFrequency] forKey: @kKeyStimFrequency];
	
	[recInfoDict setObject: [NSNumber numberWithFloat: ergStimulator.backgroundInCdPerMetersquare] forKey: @kKeyBackgroundLuminance];
	[recInfoDict setObject: ergStimulator.backgroundColor forKey: @kKeyBackgroundColor];

    [recInfoDict setObject: [NSNumber numberWithFloat: prefsController.amplificationFactor] forKey: @kKeyAmplificationFactor];
	[recInfoDict setObject: [NSNumber numberWithBool: [ergAmplifier isHardwareOk]] forKey: @kKeyisHardwareOk];

	[ergSaving saveTracesOD: traceOD andOS: traceOS andFlash: traceTrigger andDict: recInfoDict];

	[prefsController setEPNumber: epNum];
	//		[prefsController setSubjectname: [fieldSubjectName stringValue]];
	doesRecordingNeedSaving = NO;
    NSArray *guiElements = [[NSArray alloc] initWithObjects: buttonRetrievePIZ_outlet, fieldERGNumber, fieldSubjectName, fieldSubjectPIZ, dateFieldBirthDate, fieldAcuityOD, fieldAcuityOS, fieldReferrer, fieldDiagnosis, fieldRemark, nil];
    for (id e in guiElements) [e setEnabled: NO];
    [guiElements release];
}



#pragma mark automatic repeats BEGIN
- (void) setAutoStateAndButtons: (BOOL) toAutoMode {
	_isInAutoMode = toAutoMode;
	if (_isInAutoMode) {
		[buttonAutoRecordStart_outlet setEnabled: NO]; [buttonAutoRecordStop_outlet setEnabled: YES];
        [boxAutoRecordFrame_outlet setFillColor: [NSColor redColor]];
	} else {
		[buttonAutoRecordStart_outlet setEnabled: YES]; [buttonAutoRecordStop_outlet setEnabled: NO];  [boxAutoRecordFrame_outlet setFillColor: [NSColor colorWithDeviceWhite: 0.0 alpha:0.0]];
	}
}
 
- (void) autoRecordStop {
	if (!_isInAutoMode) return;
	[self setAutoStateAndButtons: NO];
	[timerAutoRecordStart invalidate];  [timerAutoRecordSave invalidate];
    [self setAutoRecordRepeatCount: autoRepeatCounterAtStart];
    [ergStimulator doBeep]; // indicate we're done
    timerAutoRecordDone = [[NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(buttonKeepAndNext:) userInfo: nil repeats: NO] retain];
}
- (void) handleAutoRecordTimerSaving: (NSTimer *) timer {
	if (!_isInAutoMode)  {
		[timerAutoRecordSave invalidate]; return;
	}
	[self keepAndAgain];
}
- (void) oneStepOfAutoRecordingTimer {
	if (!_isInAutoMode) return;
/*    if ((ergRepeatCount == 5) || (ergRepeatCount == 15)) {
        [camera setStillImageFilePathName: [NSString stringWithFormat: @"%@/%@%03u-%02u", [Misc pathOfApplicationContainer], [Misc epNum2fullString: epNum], ergSequencer.stateInSequence+1, ergRepeatCount]];
        [camera takeStillImage];
    } */
	[self initMeasurement];
    [self setAutoRecordRepeatCount: autoRecordRepeatCount - 1];
	if ((ergRepeatCount >= (NSUInteger) kMaxRepetitionsPerStimulus) || (autoRecordRepeatCount <= 0))
		[self autoRecordStop];
	else
		timerAutoRecordSave = [[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(handleAutoRecordTimerSaving:) userInfo: nil repeats: NO] retain];
}
- (void) handleAutoRecordingTimer: (NSTimer *) timer {
	if (!_isInAutoMode)  {
		[timerAutoRecordStart invalidate]; return;
	}
	[self oneStepOfAutoRecordingTimer];
}
- (IBAction) buttonAutoRecordStart: (id)sender {
	if (_isInAutoMode) return;
    autoRepeatCounterAtStart = autoRecordRepeatCount;
	[self setAutoStateAndButtons: YES];
    [self oneStepOfAutoRecordingTimer];
	timerAutoRecordStart = [[NSTimer scheduledTimerWithTimeInterval: 1.0/[ergSequencer flashFrequency] target: self selector: @selector(handleAutoRecordingTimer:) userInfo: nil repeats: YES] retain];
}
- (IBAction) buttonAutoRecordStop: (id)sender {
	if (_isInAutoMode)  [self autoRecordStop];
}
///////////////////////////// automatic repeats END


#pragma mark deal with all other buttons BEGIN
- (IBAction) buttonRecord:(id)sender {
	if (!_isInAutoMode) [self initMeasurement];
}
- (IBAction) buttonKeepAndNext: (id)sender {
	if (_isInAutoMode) return;
	[self saveMeasurement];
	self.ergState = ergSequencer.stateInSequence+1;
    [self buttonsStandardEnabledState];
}
- (void) keepAndAgain {
    [self saveMeasurement];
    [self setErgRepeatCount: ergRepeatCount + 1];
    [self buttonsStandardEnabledState];
}
- (IBAction) buttonKeepAndAgain: (id)sender {
	if (!_isInAutoMode) [self keepAndAgain];
}
- (IBAction) buttonForget: (id)sender {
	if (_isInAutoMode) return;
	doesRecordingNeedSaving = NO;
	for (EyeCode e=OD; e<=OS; e=(EyeCode)(e+1))	[[self getTraceBoxOfState: ergSequencer.stateInSequence andEye: e] forgetLastTrace];
	[self buttonsStandardEnabledState];
}

- (IBAction) buttonTimeReset: (id)sender {
	[ergTime release];  ergTime = [[NSDate date] retain];
}
- (IBAction) buttonRetrievePIZ:(id)sender {	//	NSLog(@"buttonRetrievePIZ");
	PIZ2Patient *pIZ2Patient = [[PIZ2Patient alloc] init];  [pIZ2Patient retrieveViaPIZ:  fieldSubjectPIZ.intValue];	// 16042455
	fieldSubjectName.stringValue = pIZ2Patient.subjectName;  dateFieldBirthDate.dateValue = pIZ2Patient.subjectBirthdate;
	[pIZ2Patient release];
}


- (IBAction) buttonAmpInput: (id)sender {
	[self setAmplifierConsideringStateWithOpen: ![ergAmplifier inputOpenOnChannel: 0]];
}
- (void) setAmpInputButtonTitle {
    [buttonAmpInput_outlet setTitle: [ergAmplifier inputOpenOnChannel: 0] ? [NSString stringWithUTF8String: "Input Ø"] : @"Input +"];
}


- (IBAction) buttonFoto: (id)sender {   //NSLog(@"%s", __PRETTY_FUNCTION__);
    [camera setStillImageFilePathName: [NSString stringWithFormat: @"%@/%@%@", [Misc pathOfApplicationContainer], [Misc epNum2fullString: epNum], [Misc date2HH_MM_SSdotted: [NSDate date]]]];
	[camera takeStillImage];
}


- (IBAction) buttonAmpCal: (id)sender {
    [self setAmplifierConsideringStateWithOpen: NO];
	[self initMeasurement];
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, false);	// delay until measurement is over
	EDGWaveStats *waveStats = [[EDGWaveStats alloc] initWithNSArray: traceOD];  // calibration calculation
    CGFloat min = waveStats.min, span = waveStats.span;
	NSLog(@"%gspan: ", span);
	#define kHistoSize 100
	CGFloat histogram[kHistoSize]={0};	for (NSUInteger i=0; i<kHistoSize; i++) histogram[i]=0;
	for (NSUInteger i=0; i<traceOD.count; i++) {
		NSInteger h = (NSUInteger) round((kHistoSize-1.0)*([[traceOD objectAtIndex: i] floatValue]-min)/span); //NSLog(@"%d", h);
		if ((h>=0) && (h<kHistoSize)) histogram[h]++;
	}
	[waveStats evaluateCArray: histogram count: kHistoSize];  span = [waveStats span];
	NSMutableArray *traceHistoOD=[NSMutableArray arrayWithCapacity: kHistoSize];
	for (NSUInteger i=0; i<kHistoSize; i++) [traceHistoOD addObject: [NSNumber numberWithFloat: histogram[i]]];
	NSRect coordRect = NSMakeRect(0, (CGFloat)-0.1*span, kHistoSize, (CGFloat)1.1*span);
	[self tellTracebox: [self getTraceBoxOfState: [ergSequencer stateInSequence] andEye: OD] setCoords: coordRect andAddTrace: traceHistoOD];
	
	for (NSUInteger k=0; k<10; k++) {	// smoothing, with 0 outside
		CGFloat fL=0;
		for (NSUInteger i=0; i<kHistoSize-1; i++) {
			CGFloat fNew = (fL + 2.0*histogram[i] + histogram[i+1]) / 4.0; fL = histogram[i];	histogram[i] = fNew;
		}
		histogram[kHistoSize-1] = (fL+2.0*histogram[kHistoSize-1] + 0.0) / 4.0;
	}
	
	[waveStats evaluateCArray: histogram count: kHistoSize];  span = [waveStats span];
	[traceHistoOD removeAllObjects];
	for (NSUInteger i=0; i<kHistoSize; i++) [traceHistoOD addObject: [NSNumber numberWithFloat: histogram[i]]];
	coordRect = NSMakeRect(0, (CGFloat)-0.1*span, kHistoSize, (CGFloat)1.1*span);
	[self tellTracebox: [self getTraceBoxOfState: [ergSequencer stateInSequence] andEye: OD] setCoords: coordRect andAddTrace: traceHistoOD];
	[waveStats release];
}
///////////////////////////// deal with all other buttons END


- (IBAction) popupSequenceAction:(id)sender {
	[ergSequencer setSelectedSequence: [popupSequence_outlet indexOfSelectedItem]];  [self setErgState: 0];
}
- (IBAction) buttonSequenceWhat:(id)sender {
    NSString *s = [ergSequencer allSettingsString];
	NSRunInformationalAlertPanel(@"Stimulus sequence", s, @"OK", NULL, NULL);
}


- (IBAction) checkboxInfraredOn:(id) sender {//NSLog(@"%s", __PRETTY_FUNCTION__);
	[ergStimulator setInfraredIllumination: [sender state]];
}


- (IBAction) checkboxRedBackgroundOn: (id) sender {
    if ([sender state]) {
        [ergStimulator setBackgroundColorFromWGOKBR: @"R"];
        [ergStimulator setBackgroundInCdPerMetersquare: 50.0];
    } else {
        [ergStimulator setBackgroundInCdPerMetersquare: 0.0];
        [ergStimulator setBackgroundColorFromWGOKBR: @"W"];
    }    
}



- (BOOL) acceptsFirstResponder { return YES; }


- (void) setMenuBarVisible: (BOOL) theState {
	_isMenuBarVisible = theState;
	[prefsController setMenuBarVisible: theState];
	[NSMenu setMenuBarVisible: theState];  [window setFrameTopLeftPoint: NSMakePoint(0, 9999)];
}

- (void) setAutoHideOtherApplications: (BOOL) theState {
	_isAutoHideOtherApplications = theState;
	[prefsController setAutoHideOtherApplications: theState];
	if (theState)
		[[NSApplication sharedApplication] hideOtherApplications: self];
	else {
		[[NSApplication sharedApplication] unhideAllApplications: self];
		[window makeKeyAndOrderFront: self];
	}
}


#pragma mark Termination stuff
- (void)applicationWillTerminate:(NSNotification *)notification { //NSLog(@"%s", __PRETTY_FUNCTION__);
	[window release];  [self release];
} 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app {	//NSLog(@"%s", __PRETTY_FUNCTION__);
	_isInAutoMode = NO;	// so auto-repeat timers (possibly active) will not run amok
	// we don't ask for confirmation if we've done ≥ 2 flicker measurements
	BOOL mayTerminate = ((([ergSequencer stateInSequence]+1) >= ([ergSequencer numberOfStates])) && (ergRepeatCount >= 1));
	if (!mayTerminate)
		mayTerminate = (NSRunAlertPanel(@"Do you really want to quit?", @"", @"No", @"Yes", NULL) == NSAlertAlternateReturn);
	if (!mayTerminate)  return NSTerminateCancel;
	// so now we will terminate, let's gracefully shutdown
	[self saveMeasurement];  [ergSaving release];  [prefsController release];
	[timer100Hz invalidate];  [timer100Hz release];  timer100Hz = nil;
	[ergAmplifier release];  [ergStimulator release];
	[traceOD release]; [traceOS release]; [traceTrigger release];	[recInfoDict release];  [ergTime release];
	[camera stopAndClose];	[camera release];
	return NSTerminateNow;
}

@end
