// MainController
//
//
//	history ––> Globals.h
//
#import <Cocoa/Cocoa.h>
#import <QTKit/QTkit.h>
#import "Oscilloscope3.h"
#import "Q450Stim.h"
#import "RCAmpNI.h"
#import "TraceBox2.h"
#import "PrefsController.h"
#import "Sequencer.h"
#import "Saving.h"
#import "PIZ2Patient.h"
#import "EDGInfoPanel.h"
#import "EDGWaveStats.h"
#import "Globals.h"
#import "Camera2.h"
#import "Misc.h"
#import "ReferrerNames.h"


@interface MainController: NSWindowController {
	IBOutlet NSWindow *window;
	IBOutlet Oscilloscope3 *osci;
	IBOutlet NSTextField *fieldSubjectName, *fieldSubjectPIZ, *fieldERGNumber;
	IBOutlet NSDatePicker *dateFieldBirthDate;
	IBOutlet NSTextFieldCell *fieldAcuityOD, *fieldAcuityOS;
	IBOutlet NSComboBox *fieldReferrer;
	IBOutlet NSTextField *fieldDiagnosis, *fieldRemark;
	IBOutlet NSTextField *fieldFlashStrength, *fieldFlashFreq, *fieldFlashColor, *fieldBackgroundLum, *fieldBackgroundColor, *fieldRepeatCount;
	IBOutlet NSTextField *fieldTimeDisplay;
	IBOutlet NSTextField *fieldStimNameISCEV;
	IBOutlet QTCaptureView	*mCaptureView;	// VideoIn -> View
	Camera2* camera;
	
	IBOutlet NSButton *buttonRecord_outlet, *buttonKeepAndNext_outlet, *buttonKeepAndAgain_outlet,
        *buttonForget_outlet, *buttonRetrievePIZ_outlet, *buttonAmpInput_outlet, *buttonAmpCal_outlet,
        *buttonAutoRecordStart_outlet, *buttonAutoRecordStop_outlet, *checkboxInfraredOn_outlet;
	IBOutlet NSPopUpButton* popupSequence_outlet;
	IBOutlet NSBox *boxAutoRecordFrame_outlet;
	
	NSUInteger epNum, ergRepeatCount, autoRecordRepeatCount, ergState;
	BOOL isDoingSweepAcquisition, doesRecordingNeedSaving, in100Handler, _isMenuBarVisible, _isAutoHideOtherApplications, _isInAutoMode;
	NSDate *ergTime;

	dispatch_source_t timerFlicker;

	RCAmpNI *ergAmplifier;
	Q450Stim *ergStimulator;
	NSArray *traceOD, *traceOS, *traceTrigger;
	PrefsController *prefsController;
	Sequencer* ergSequencer;
	Saving *ergSaving;
	NSMutableDictionary *recInfoDict;
    ReferrerNames *referrerNames;
	NSMutableArray *traceBoxesOD, *traceBoxesOS;
}

- (IBAction) buttonAutoRecordStart: (id)sender;
- (IBAction) buttonAutoRecordStop: (id)sender;
- (IBAction) buttonRecord: (id)sender;
- (IBAction) buttonKeepAndNext: (id)sender;
- (IBAction) buttonKeepAndAgain: (id)sender;
- (IBAction) buttonForget: (id)sender;
- (IBAction) buttonTimeReset:(id)sender;
- (IBAction) buttonRetrievePIZ:(id)sender;
- (IBAction) buttonAmpInput:(id)sender;
- (IBAction) buttonFoto:(id)sender;
- (IBAction) popupSequenceAction:(id)sender;
- (IBAction) buttonSequenceWhat:(id)sender;
- (IBAction) checkboxInfraredOn: (id) sender;
- (IBAction) checkboxRedBackgroundOn: (id) sender;

- (void) buttonsAllDisable;
- (void) buttonsStandardEnabledState;
- (void) setAmplifierConsideringStateWithOpen: (BOOL) open;

- (TraceBox2 *) getTraceBoxOfState: (NSUInteger) theState andEye: (EyeCode) theEye;
- (void) tellTracebox: (TraceBox2 *) tracebox setCoords: (NSRect) coordRect andAddTrace: (NSArray *) trace;

- (void) saveMeasurement;

- (void) setERGNumberFromPreviousSession;

- (void) setMenuBarVisible: (BOOL) theState;
- (void) setAutoHideOtherApplications: (BOOL) theState;

- (void) keepAndAgain;	// for internal use
- (void) setAutoStateAndButtons: (BOOL) toAutoMode;	// for internal use

@property (assign) NSUInteger ergState;
@property (assign) NSUInteger epNum;
@property (assign) NSUInteger autoRecordRepeatCount;
@property (assign) NSUInteger ergRepeatCount;

@end
