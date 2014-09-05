/*
 *  Globals.h
 *  ERG2007
 *
 *  Created by bach on 26.12.2006.
 *  Copyright 2006–2011 Prof. Michael Bach. All rights reserved.
 */


#define kCurrentVersionDate "2014-09-05"

/*	History
	=======

2014-09-05  change parameter handover to saving not to use a dictionary
2014-09-04  return value of retrieveViaPIZ is considered
2014-08-01  switched to NI-Daq rather bTop, switched to Roland-Consult rather Toennies amplifiers
            has to stay in 32-bit mode because of NI
            different amplification calibration concept (rely on RC amplfactor, rely on NI amplfactor)
            added some bindings
2011-08-04	switched to the new version of EDGSerial which doesn't really help much here because we're using both the Keyspan USA and the Rol-Cons serial device
2011-02-07a	removed error in 30 Hz flash block (can't reuse a local static variable, strangely enough). The "__block" for the outer counter helped, with that I can decrement.
2011-02-07	built for ppc + 386, clears occasional macam errors?
2011-01-27	for compatibility with Macam 0.9.2: 32 bit Universal, no garbage collection
2010-10-20	removed "tinaTaiVersion"
2010-08-09	added checkbox controlling infrared background (off for calibration)
2010-06-02	removed an outdated range check for the flash duration
2010-06-01	improved the Q450 control so the full flash strengths range up to 30 works even with background
2010-05-25	improved TraceBox(2) so that it is now dynamic and not added in IB; this allows to have a huge number of stimuli per sequence.
			rearranged the sequence-select popup disable to happen on InitMeasurement.
2010-05-18	rearranged Q450 control so flash color is set BEFORE flash strength, otherwise it will use the previous color
2010-05-17	first test with new program fine, but the 50 ms preamble was missing for the flicker, now added.
2010-05-11	slight changes to variable typs in Q450, flicker trace prolonged to 2 s, 
			replaced CFRunLoop by usleep in ToenniesAMp & Q450 (solved crash and less leaking messages)
			changed hi pass for photopic ERG from 3 Hz to 1 Hz
2010-02-23	added the new oscilloscope
2010-02-19	added new version of PIZ2Pat.jar, found out that the jar-errors in linking are avoided by removing the jars from the "Link Binary With L." folder in Target
2010-02-16	finished switching to property list file, added a default when none is found
2010-02-15	switched Flicker timing to a dispatch timer
			the dictionary describing the stimulus is now read from a property list file
2010-02-10	changed the wavename nomenclature to numbers for the blocks, thus it is now easy to record more than 26 blocks=trials
			implemented the flicker stimulation with a GCD timer (so it should be very exact)
2009-12-30	switched on more error checks for building, moved a few code pieces around to avoid forward references
2009-11-25	added "_outlet" to IBOutlets, to better discern when they're also IBActions
2009-06-09	had loss of analog input. Possible cause: jolt from switch on the stimulator. Consequently added flash trigger channel,
			had to enlarge interface for 3rd oscilloscope, and made record traces larger too.
			Sometimes "voltageAtChannel, btLib_ReadADValues returned != 0: -3" -- occasionally the bTop2 gets a glitch.
			Error "*** -[NSLock lock]: deadlock (<NSLock: 0x168cb0> '(null)') … Break on _NSLockError() to debug." is due to the Quicktime kit / Macam.
2009-05-29	set correct addresses for the USB devices q450 and USB<—>serial to work with the new Mac mini, slight rearrangements in awakeFromNib
2009-05-11	improved handling of auto-repeat
2009-03-05	calculated correctly the number of flicker pulses to fill the full flicker trace
2009-03-04	fixed bug that didn't set the background luminance after changing colour
2009-03-02	added sequence to compare old & new "photopic 2007/2009"
2009-02-27	redefined key "kKeyFlashStrength" to "flashStrength" in synchrony with the analysis program
2009-02-26	background & flash off wenn quitting, infrared testing: ok. Made flash calibration: fine for high levels.
			camera from Q450 not working reliably, externalised
			increased length of flicker trace to 1360 ms (bound by buffer in bTop-2)
2009-02-13	changed layout to allow 11 traces. Increased flicker length from 1000 to 2000 ms.
2008-12-05	"auto repeat recording" now built in. The logic is not yet totally satisfactory, but it works.
			refactoring doesn't work in C++ mode (*.mm extenstion)
2008-12-02	now it is possible to select from a range of stimulus sequences; also got rid of trailing zeros (%g!)
2008-12-01	Sequencer now works with a dictionary, much more elegant for inputting step values
2008-11-25	introduced the class "Sequencer" to better deal with future expansion to a variety of conditions
2008-11-04	added colours and flash duration / luminances to file saving, colours to interface
2008-10-28	began sequence structure
2008-10-26	works with Q450
2008-03-26	all settings to 10.5 & i368
2007-09-06	changed button text to "Forget & again", allowed PIZ from 6-9 digits
2007-06-16	added "isHardwareOk" to the dictionary. Thus we can better deal with the demo mode, 
			namely skipping the flash time detection
2007-05-20	Changed "AnalogInput" to enjoy the advantage of the bTop-2 replacement. 
			No more glitches, no more hardware noise, and bipolar mode works now. 
			Gain of Toennies needed to be reduced, because input resistance is now higher
2007-04-25	disabled the field of the ERG number after the first save. This avoids accidental changes.
2007-04-13	more trials with the new bipolar bTop, doesn't work yet. Change format of the acuity field to allow more places
2007-04-10	bTop is now in "glitch free" mode without going to the previous copy, although it still needs the copy kludge
			flash trace is also saved now, rewrote saving to duplicate less code
2007-03-23	triggered record by "⌘↵" to avoid a flash when reading the PIZ via the bar code reader
2007-03-21	common code base for ERG & EOG (Toennies / Nicolet / Serial / InfoPanel / PIZ2Patient / CameraStuff / WndwViewportXform)
2007-03-16	removed outo-repeat from the stepper
2007-03-15	added a stepper for the ERG state. Had to move the confirmation dialog around
2007-03-01	removed too much: spadbc is a necessary java module
2007-02-27a	removed 2 large libraries from the PIZ library which are not necessary
2007-02-24	using Notifications & addObserver, made text fields more robust (removed unicode entries)
2007-02-19	changed referrer into a ComboBox, reads its values from "edgReferrerList.plist"
			hid the effects of the occasional 0xFFF output from the ADC by replacing with previous values
2007-01-30	fixed error in non-localised amplification settings (Preferences),
			improved behaviour of incomplete calibration button
			began work on autocompletion for the referrer list
2007-01-29	architecture (ppc vs i386) must be set both for build and target (??)
			speeded up Toennies: only send data when different from current one
			(a) inadvertently had set the created filenames also to "ERG2007"
2007-01-27	long search where to set the product name, corrected some menu names (to ERG2007)
			added capability to hide all other applications
			switched on many more warnings, and found 1 error in Toennies (0x0A comparison)

defaults write com.apple.xcode PBXCustomTemplateMacroDefinitions '{ORGANIZATIONNAME = "Prof. Michael Bach" ; }'

2007-01-26	added modal EDGInfoPanel (for Amplifier & Stimulator)
			removed menubar, made window textured. Thus everything is dark (and can be moved to top, which looks nicer to me)
			began work on auto-calibration
			oscilloscope trace colour now in "live editing" mode via key-value-coding from the prefs window. Needs accessor function.
			added menuBarVisibility to preferences
2007-01-25	in "PIZ2Patient" the string returned from Andreas' Java program through the pipe needed NSMacOSRomanStringEncoding,
			otherwise there was an error when saving! (because saving also uses NSMacOSRomanStringEncoding)
2007-01-23a	removed the closing of the amps before setting ERG2007 standard, a bit faster
2007-01-23	2 problems with Toennies solved:
			1. needs to be addressed more slowly (0.3 s delay after each command was not long enough)
			2. the format "%d" on "round(xx)" produces many trailing digits, needs to be converted to int
			the hipass for photopic is now set at 3 Hz
2007-01-22	fixed an error in the wavenote saver introduced by date improvement (gs)
			Toennies amp now fully works. Fixed crash (camera must not be released)
2007-01-21	added Toennies control, all internal variables now start with _
2007-01-18	Date correctly formatted as YYYY-MM-DD
2007-01-16	PIZ stuff now copied here into the project resources, does not rely on the server path any more. 
				Needed a special "copy files" part in Targets… to create the sub-folder "lib"
2007-01-15	converting the PIZ now works
			made camera slower, 5 Hz, otherwise the system is too busy. But we don't have a good video device anyway (yet).
2007-01-14	Preferences instead of settings & last session
2007-01-12	corrected background level, set up calibration, FIRST MEASUREMENT!!!
			calibration: the Toennies output seems to have an impedance of ≈ 10 kOhm, so with the 
						low input impedance of the bTop-2 (of 5 kOhm due to unipolar pull-up) there 
						is marked amplitude loss which has to be compensated by calibration.
						The aim is to have a ± 400 µV range
			window background is darkened so the room is not lit up by the VDU
2007-01-11	Quitting now checks for unsaved measurements.
			traces have background & frame, flicker stimulus works
2007-01-09	analog input now works. Everything scaled to voltage of ADC (±2.5 V)
			bipolar did not work, pulled open input to 2.5 V, 
			AC coupling therefore necessary (input resistance ca. 5 kOhms)
2007-01-07	2 traces work, implemented settings access & initials of saving
2006-12-19	begun

*/


#define versionEDIAG
//  #define versionAnimal
//	#define versionTinaTsai



#define kTinatTsaiVEPAmplificationMultiplier 10.0

// The following unit simply derives from the amplification factor
#define kDefaultAmplificationFactor 10000.0

#define kMaxRepetitionsPerStimulus 100
#define kNumPointsOscilloscope 1000

// values in milliseconds. The flicker trace length is NOT determined by a 4 k buffer in the bTop-2 as I had thought (2010-05-11)
#define kLengthNonflickerTraceInMs 250
//#define kLengthFlickerTraceInMs 1360
#define kLengthFlickerTraceInMs 3000

// values in seconds
#define kSampleIntervalOscilloscopeInS 0.025
#define kSampleIntervalERGInMs 0.001


enum EyeCode {OD=0, OS, ONone};


// keys for the dictionary and for saving of data.
// Version of data acquisition program
#define kKeyVersion "vs"
#define kKeyEPNumber "epNum"
// block number. Change 2010-02-10: no more letters, but numbers 0–xxx [was (0=A, 1=B, …)]
#define kKeyBlockNumber "blockNum"
// stimulus number, 0-xx
#define kKeyStimNumber "stimNum"
// channel numbers start with 0 internally and in saved records, but usually with 1 in the user interface
#define kKeyChannel "channel"
#define kKeyDateRecording "date"
#define kKeyTimeRecording "time"
// standard sequence: surname, given name
#define kKeySubjectName "subjectName"
#define kKeyDateBorn "dateBorn"
#define kKeySubjectPIZ "subjectPIZ"
#define kKeyAcuityOD "acuityOD"
#define kKeyAcuityOS "acuityOS"
#define kKeyDoctor "physician"
#define kKeyDiagnosis "diagnosis"
#define kKeyRemark "remark"
#define kKeyEyeKey "eyeKey"
// type of EP: (P)ERG2007 / VEP / Oz, O1, …
#define kKeyEPKey "epKey"
// flash strength, in cd·s/sqm
#define kKeyFlashStrength "flashStrength"
#define kKeyFlashColor "flashColor"
// flash duration in seconds
#define kKeyFlashDuration "flashDuration"
// flash luminance in cd/m²
#define kKeyFlashLuminance "flashLuminance"
// background luminance, in cd·s/sqm
#define kKeyBackgroundLuminance "backgroundLuminance"
#define kKeyBackgroundColor "backgroundColor"
#define kKeyStimName "stimName"

#define kKeyStimNameISCEV "stimNameISCEV"
#define kKeyStimDescription "stimDescription"
#define kKeyStimFrequency "frequency"
#define kKeySingleOrFlicker "singleOrFlicker"
#define kKeyisHardwareOk "isHardwareOk"

#define kKeyAmplificationFactor "amplificationFactor"

