#import "QBPopupMenu/QBPopupMenu.h"
#include <objc/runtime.h>
#include <objc/message.h>
#include <dlfcn.h>
#import "NSTask.h"


#define PREFERENCES_PATH @"/var/mobile/Library/Preferences/com.imokhles.phenhancerprefs.plist"
#define PREFERENCES_CHANGED_NOTIFICATION "com.imokhles.phenhancerprefs.preferences-changed"

#define kPreferencesPath @"/var/mobile/Library/Preferences/com.imokhles.phenhancerprefs.plist"
#define kPreferencesChanged "com.imokhles.phenhancerprefs.preferences-changed"

#define PREFERENCES_ENABLED_PHeditNum_KEY @"editNum"
#define PREFERENCES_ENABLED_PHnewButtons_KEY @"newButtons"
#define PREFERENCES_ENABLED_PHtabPrefs_KEY @"tabPrefs"
#define PREFERENCES_ENABLED_PHrmVoCal_KEY @"rmVoCal"
#define PREFERENCES_ENABLED_PHrmFavBar_KEY @"rmFavBar"
#define PREFERENCES_ENABLED_PHrmRcnBar_KEY @"rmRcnBar"
#define PREFERENCES_ENABLED_PHrmCntBar_KEY @"rmCntBar"
#define PREFERENCES_ENABLED_PHrmKbdBar_KEY @"rmKbdBar"

#define PREFERENCES_ENABLED_PHnoVoKey_KEY @"noVoKey"

#define PREFERENCES_ENABLED_PHredirectAPP_KEY @"redirectApp"

#define PREFERENCES_ENABLED_PHftInsid1_KEY @"ftInsid1"
#define PREFERENCES_ENABLED_PHftInsid2_KEY @"ftInsid2"
#define PREFERENCES_ENABLED_PHftInsid3_KEY @"ftInsid3"
#define PREFERENCES_ENABLED_PHftInsid4_KEY @"ftInsid4"
#define PREFERENCES_ENABLED_PHftInsid5_KEY @"ftInsid5"
#define PREFERENCES_ENABLED_PHftInsid6_KEY @"ftInsid6"

#define PREFERENCES_ENABLED_PHstPrefs_KEY @"stPrefs"

#define PREFERENCES_ENABLED_PHConPhoto_KEY @"ConPhoto"
#define PREFERENCES_ENABLED_PHConLabel_KEY @"ConLabel"
#define PREFERENCES_ENABLED_PHConGlyph_KEY @"ConGlyph"

static BOOL editNum = NO;
static BOOL newButtons = NO;
// static BOOL rmVoCal = NO;
static BOOL noVoKey = NO;
static BOOL redirectApp = NO;
static BOOL redirectTo = NO;
static BOOL callClosed = NO;
// static BOOL ftInsid = NO;
static NSMutableDictionary *plist;
static NSInteger stylePrefs;

static NSInteger tabsPrefs;

static NSInteger vcPrefs;
static NSInteger favPrefs;
static NSInteger rcnPrefs;
static NSInteger cntPrefs;
static NSInteger kbdPrefs;

static NSInteger ft1Prefs;
static NSInteger ft2Prefs;
static NSInteger ft3Prefs;
static NSInteger ft4Prefs;
static NSInteger ft5Prefs;
static NSInteger ft6Prefs;

static NSInteger conPhotoPrefs;
static NSInteger conLabelPrefs;
static NSInteger conGlyphPrefs;

static UIImage *delImage;
static UIImage *addImage;
// static int intYES = [[NSNumber numberWithBool:YES]intValue];
// static int intNO = [[NSNumber numberWithBool:NO]intValue];

@interface UIImage (MGTint)

- (UIImage *)imageTintedWithColor:(UIColor *)color;
- (UIImage *)imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction;
@end

@implementation UIImage (MGTint)


- (UIImage *)imageTintedWithColor:(UIColor *)color
{
	// This method is designed for use with template images, i.e. solid-coloured mask-like images.
	return [self imageTintedWithColor:color fraction:0.0]; // default to a fully tinted mask of the image.
}


- (UIImage *)imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction
{
	if (color) {
		// Construct new image the same size as this one.
		UIImage *image;
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
		if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
			UIGraphicsBeginImageContextWithOptions([self size], NO, 0.f); // 0.f for scale means "scale for device's main screen".
		} else {
			UIGraphicsBeginImageContext([self size]);
		}
#else
		UIGraphicsBeginImageContext([self size]);
#endif
		CGRect rect = CGRectZero;
		rect.size = [self size];

		// Composite tint color at its own opacity.
		[color set];
		UIRectFill(rect);

		// Mask tint color-swatch to this image's opaque mask.
		// We want behaviour like NSCompositeDestinationIn on Mac OS X.
		[self drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0];

		// Finally, composite this image over the tinted mask at desired opacity.
		if (fraction > 0.0) {
			// We want behaviour like NSCompositeSourceOver on Mac OS X.
			[self drawInRect:rect blendMode:kCGBlendModeSourceAtop alpha:fraction];
		}
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		return image;
	}

	return self;
}

@end

static void PHEnhancerInitPrefs() {
    NSDictionary *PHEnhancerSettings = [NSDictionary dictionaryWithContentsOfFile:kPreferencesPath];


    NSNumber *enableTweakNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHeditNum_KEY];
    editNum = enableTweakNU ? [enableTweakNU boolValue] : 1;
    NSNumber *redirectAppNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHredirectAPP_KEY];
    redirectApp = redirectAppNU ? [redirectAppNU boolValue] : 1;
    NSNumber *newButtonsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHnewButtons_KEY];
    newButtons = newButtonsNU ? [newButtonsNU boolValue] : 0;
    NSNumber *noVoKeyNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHnoVoKey_KEY];
    noVoKey = noVoKeyNU ? [noVoKeyNU boolValue] : 1;
    NSNumber *stylePrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHstPrefs_KEY];
    stylePrefs = stylePrefsNU ? [stylePrefsNU intValue] : 0;
    NSNumber *tabsPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHtabPrefs_KEY];
    tabsPrefs = tabsPrefsNU ? [tabsPrefsNU intValue] : 4;
    NSNumber *vcPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHrmVoCal_KEY];
    vcPrefs = vcPrefsNU ? [vcPrefsNU intValue] : 1;
    NSNumber *favPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHrmFavBar_KEY];
    favPrefs = favPrefsNU ? [favPrefsNU intValue] : 1;
    NSNumber *rcnPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHrmRcnBar_KEY];
    rcnPrefs = rcnPrefsNU ? [rcnPrefsNU intValue] : 1;
    NSNumber *cntPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHrmCntBar_KEY];
    cntPrefs = cntPrefsNU ? [cntPrefsNU intValue] : 1;
    NSNumber *kbdPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHrmKbdBar_KEY];
    kbdPrefs = kbdPrefsNU ? [kbdPrefsNU intValue] : 1;
    NSNumber *ft1PrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHftInsid1_KEY];
    ft1Prefs = ft1PrefsNU ? [ft1PrefsNU intValue] : 1;
    NSNumber *ft2PrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHftInsid2_KEY];
    ft2Prefs = ft2PrefsNU ? [ft2PrefsNU intValue] : 1;
    NSNumber *ft3PrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHftInsid3_KEY];
    ft3Prefs = ft3PrefsNU ? [ft3PrefsNU intValue] : 1;
    NSNumber *ft4PrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHftInsid4_KEY];
    ft4Prefs = ft4PrefsNU ? [ft4PrefsNU intValue] : 1;
    NSNumber *ft5PrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHftInsid5_KEY];
    ft5Prefs = ft5PrefsNU ? [ft5PrefsNU intValue] : 1;
    NSNumber *ft6PrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHftInsid6_KEY];
    ft6Prefs = ft6PrefsNU ? [ft6PrefsNU intValue] : 1;

    NSNumber *conPhotoPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHConPhoto_KEY];
    conPhotoPrefs = conPhotoPrefsNU ? [conPhotoPrefsNU intValue] : 1;
    NSNumber *conGlyphPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHConGlyph_KEY];
    conGlyphPrefs = conGlyphPrefsNU ? [conGlyphPrefsNU intValue] : 1;
    NSNumber *conLabelPrefsNU = PHEnhancerSettings[PREFERENCES_ENABLED_PHConLabel_KEY];
    conLabelPrefs = conLabelPrefsNU ? [conLabelPrefsNU intValue] : 0;


    // if ([cText length] == 0 || [cText isEqualToString:@""]) {
    // 	NSMutableDictionary *mutableDict = PHEnhancerSettings ? [PHEnhancerSettings mutableCopy] : [NSMutableDictionary dictionary];
	   //  [mutableDict setObject:@"via PHEnhancer" forKey:kTWBCTextKey];
	   //  [mutableDict writeToFile:kPreferencesPath atomically:YES];
    // }
    //

}

@protocol DialerLCDFieldDelegate <NSObject>
@optional
-(void)dialerField:(id)field stringWasPasted:(id)pasted;
-(void)dialerLCDFieldTextDidChange:(id)dialerLCDFieldText;
@end

@protocol DialerLCDFieldProtocol <NSObject>
-(void)setDelegate:(id)delegate;
-(void)setHighlighted:(BOOL)highlighted;
-(BOOL)highlighted;
-(void)setInCallMode:(BOOL)callMode;
-(BOOL)inCallMode;
-(void)deleteCharacter;
-(void)setText:(id)text needsFormat:(BOOL)format;
-(id)text;
@optional
-(void)setText:(id)text needsFormat:(BOOL)format name:(id)name label:(id)label;
-(void)setName:(id)name numberLabel:(id)label;
@end

@class PHAbstractDialerView;

@interface DialerController : UIViewController
@property(readonly, assign) PHAbstractDialerView* dialerView;
-(void)_deleteButtonDown:(id)down;
-(void)_deleteButtonClicked:(id)clicked;
-(void)_addButtonClicked:(id)clicked;
@end

@interface UIWindow ()
+(CGRect)constrainFrameToScreen:(CGRect)screen;
+(id)keyWindow;
@end

@interface PHAbstractDialerView : UIView <DialerLCDFieldDelegate>
@property(retain, nonatomic) UIView<DialerLCDFieldProtocol>* lcdView;
@property(retain, nonatomic) UIControl* deleteButton;
@property(retain, nonatomic) UIControl* callButton;
@property(retain, nonatomic) UIControl* addContactButton;
@end

@interface PHHandsetDialerView : PHAbstractDialerView
@property(retain) UIView* topBlankView;
@property(retain) UIView* bottomBlankView;
@property(retain) UIView* rightBlankView;
@property(retain) UIView* leftBlankView;
-(id)initWithFrame:(CGRect)frame;
@end

@interface TPSuperBottomBarButton : UIButton
@end

static TPSuperBottomBarButton *delSuper;
static TPSuperBottomBarButton *addSuper;
@interface PHHandsetDialerLCDView : UIView
@property(retain, nonatomic) UILabel* numberLabel;
-(void)deleteCharacter;
-(id)initWithFrame:(CGRect)frame forDialerType:(int)dialerType;
-(void)applyLayoutConstraints;
@end

@interface PHHandsetDialerLCDView (EditPhone) <UIActionSheetDelegate>
- (void)openEditAlert;
- (void)deleteChars;
- (void)optionUIActionSheet;
- (void)optionQBPopupMenu;
- (void)grabOption:(NSInteger)optionNM;
@end

@interface PhoneTabBarController : UITabBarController
-(void)showFavoritesTab:(BOOL)arg1 recentsTab:(BOOL)arg2 contactsTab:(BOOL)arg3 keypadTab:(BOOL)arg4 voicemailTab:(BOOL)arg5;
@end

@interface PhoneTabBarController (PHEnhancer)
- (BOOL)grabOptionVC:(NSInteger)optionVC;
- (BOOL)grabOptionFav:(NSInteger)optionFav;
- (BOOL)grabOptionRcn:(NSInteger)optionRcn;
- (BOOL)grabOptionCnt:(NSInteger)optionCnt;
- (BOOL)grabOptionKbd:(NSInteger)optionKbd;
@end

@interface MobilePhoneApplication : UIApplication
-(BOOL)showsFaceTimeAudioFavorites;
-(BOOL)showsFaceTimeAudio;
-(BOOL)showsFaceTime;
-(BOOL)showsFaceTimeFavorites;
-(BOOL)showsFaceTimeAudioRecents;
-(BOOL)showsFaceTimeRecents;
-(BOOL)showsPhoneVoicemail;
@end

@interface MobilePhoneApplication (PHEnhancer)
- (BOOL)grabOptionVC:(NSInteger)optionVC;
- (BOOL)grabOptionFT1:(NSInteger)optionFT1;
- (BOOL)grabOptionFT2:(NSInteger)optionFT2;
- (BOOL)grabOptionFT3:(NSInteger)optionFT3;
- (BOOL)grabOptionFT4:(NSInteger)optionFT4;
- (BOOL)grabOptionFT5:(NSInteger)optionFT5;
- (BOOL)grabOptionFT6:(NSInteger)optionFT6;
@end

@interface PHFavoritesCell : UITableViewCell
- (BOOL)shouldShowContactPhotos;
- (BOOL)shouldShowIconGlyph;
- (BOOL)shouldShowTextLabel;
@end

@interface PHFavoritesCell (PHEnhancer)
- (BOOL)grabOptionConPhoto:(NSInteger)optionConPhoto;
- (BOOL)grabOptionConLabel:(NSInteger)optionConLabel;
- (BOOL)grabOptionConGlyph:(NSInteger)optionConGlyph;
@end

@interface SBApplicationController
+(id)sharedInstance;
-(id)applicationWithDisplayIdentifier:(id)bundleIdentifier;
@end

@interface SBApplication
-(id)displayIdentifier;
@end

@interface SBUIController : NSObject
-(void)activateApplicationAnimated:(id)application;
- (BOOL)clickedMenuButton;
@end

@interface SBUIController (PHEnhancer)
- (void)PHE_CloseCall;
@end

static NSString *sahbIsdar() {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath: @"/bin/sh"];
  [task setArguments:[NSArray arrayWithObjects: @"-c", @"dpkg -s com.imokhles.PHEnhancer | grep 'Version'", nil]];
  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  [task launch];
  NSData *data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
  NSString *version = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  NSString *subString = [version substringFromIndex:[version length] - 7];
  return subString;
}

%hook SixSquareView
- (BOOL)onlyShowsFourButtons {
	if (editNum || newButtons) {
		return NO;
	}
}
%end

%hook InCallController
-(void)_handleEndOfLastCall {
	%orig;
	if (redirectApp) {
		system ("killall MobilePhone");
	}
}
%end

%hook DialerController
- (void)viewDidLoad {
    %orig;
    if (newButtons) {
	      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deleteButtonDown:) name:@"delHMokh" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deleteButtonClicked:) name:@"delMokh" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_addButtonClicked:) name:@"addMokh" object:nil];
    }
}
-(void)viewDidAppear:(BOOL)view {
  %orig;
  // PHHandsetDialerView *dialView = self.dialerView;
  delImage = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/PHEnhancerPrefs.bundle/eraser.png"];
          delImage = [delImage imageTintedWithColor:[UIColor whiteColor]];
          addImage = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/PHEnhancerPrefs.bundle/plus.png"];
          addImage = [addImage imageTintedWithColor:[UIColor whiteColor]];
          // [self.bottomBlankView setBackgroundColor:[UIColor redColor]];
          delSuper = [[objc_getClass("TPSuperBottomBarButton") alloc] init];
          delSuper.frame = CGRectMake(self.dialerView.callButton.frame.origin.x+95, self.dialerView.callButton.frame.origin.y, self.dialerView.callButton.frame.size.width, self.dialerView.callButton.frame.size.height);
          [delSuper setBackgroundColor:[UIColor redColor]];
          [delSuper setBackgroundImage:delImage forState:UIControlStateNormal];
          [delSuper addTarget:self.dialerView action:@selector(delMethod)forControlEvents:UIControlEventTouchUpInside];
          [delSuper addTarget:self.dialerView action:@selector(delHMethod)forControlEvents:UIControlEventTouchDown];
          addSuper = [[objc_getClass("TPSuperBottomBarButton") alloc] init];
          addSuper.frame = CGRectMake(self.dialerView.callButton.frame.origin.x-95, self.dialerView.callButton.frame.origin.y, self.dialerView.callButton.frame.size.width, self.dialerView.callButton.frame.size.height);
          [addSuper setBackgroundColor:[UIColor blueColor]];
          [addSuper setBackgroundImage:addImage forState:UIControlStateNormal];
          [addSuper addTarget:self.dialerView action:@selector(addMethod)forControlEvents:UIControlEventTouchDown];
          [self.dialerView addSubview:delSuper];
          [self.dialerView addSubview:addSuper];
          [delSuper setHidden:YES];
          [addSuper setHidden:YES];
}
-(void)_deleteButtonClicked:(id)clicked {
    %orig;
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test"
    //               message:[NSString stringWithFormat:@"%@", NSStringFromCGRect(self.dialerView.callButton.frame)]
    //                    delegate:self
    //                 cancelButtonTitle:@"Done"
    //                 otherButtonTitles:nil];
    //       [alert show];
}
%end

%hook PHHandsetDialerView
-(id)initWithFrame:(CGRect)frame {
   id r = %orig;
   if (r && newButtons) {
   	   	if (newButtons) {
          NSString *testLog = sahbIsdar();
          NSLog(@"%@",testLog);

       		
   	}
   }
   return r;
}
// - (void)layoutSubview {
//   %orig;
// }
-(void)updateContraintsForStatusBar {
  %orig;
}
//localizedStringForKey

%new(v@:@@)
- (void)delMethod {
   [[NSNotificationCenter defaultCenter] postNotificationName:@"delMokh" object: nil];
}
%new(v@:@@)
- (void)addMethod {
   [[NSNotificationCenter defaultCenter] postNotificationName:@"addMokh" object: nil];
}
%new(v@:@@)
- (void)delHMethod {
   [[NSNotificationCenter defaultCenter] postNotificationName:@"delHMokh" object: nil];
}
%end

%hook PHAbstractDialerView
%new(v@:@@)
- (void)delMethod {
   [[NSNotificationCenter defaultCenter] postNotificationName:@"delMokh" object: nil];
}
%new(v@:@@)
- (void)addMethod {
   [[NSNotificationCenter defaultCenter] postNotificationName:@"addMokh" object: nil];
}
%new(v@:@@)
- (void)delHMethod {
   [[NSNotificationCenter defaultCenter] postNotificationName:@"delHMokh" object: nil];
}
%end

%hook TPDialerSoundController
- (void)playSoundForDialerCharacter:(unsigned int)arg1 {
  if (noVoKey) {
    return;
  } else {
    %orig;
  }
}
%end

%hook PhoneTabBarController
-(int)currentTabViewType {
   if (tabsPrefs == 0) {
      return 1;
   }
   if (tabsPrefs == 1) {
      return 2;
   }
   if (tabsPrefs == 2) {
      return 3;
   }
   if (tabsPrefs == 3) {
      return 4;
   }
   if (tabsPrefs == 4) {
      return 5;
   }
}
-(int)defaultTabViewType {
   if (tabsPrefs == 0) {
      return 1;
   }
   if (tabsPrefs == 1) {
      return 2;
   }
   if (tabsPrefs == 2) {
      return 3;
   }
   if (tabsPrefs == 3) {
      return 4;
   }
   if (tabsPrefs == 4) {
      return 5;
   }

}
-(void)showFavoritesTab:(BOOL)arg1 recentsTab:(BOOL)arg2 contactsTab:(BOOL)arg3 keypadTab:(BOOL)arg4 voicemailTab:(BOOL)arg5 {
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
 //    vcPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmVoCal_KEY]) integerValue];
 //    favPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmFavBar_KEY]) integerValue];
 //    rcnPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmRcnBar_KEY]) integerValue];
 //    cntPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmCntBar_KEY]) integerValue];
 //    kbdPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmKbdBar_KEY]) integerValue];

	arg1 = [self grabOptionFav:favPrefs];
	arg2 = [self grabOptionRcn:rcnPrefs];
	arg3 = [self grabOptionCnt:cntPrefs];
	arg4 = [self grabOptionKbd:kbdPrefs];
	arg5 = [self grabOptionVC:vcPrefs];

	%orig(arg1, arg2, arg3, arg4, arg5);
}
%new(v@:@@)
- (BOOL)grabOptionVC:(NSInteger)optionVC {
    switch (optionVC) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFav:(NSInteger)optionFav {
    switch (optionFav) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionRcn:(NSInteger)optionRcn {
    switch (optionRcn) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionCnt:(NSInteger)optionCnt {
    switch (optionCnt) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionKbd:(NSInteger)optionKbd {
    switch (optionKbd) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%end
/*
%hook PhoneApplication
%new(v@:@@)
- (void)applicationWillEnterBackground:(UIApplication *)application {
	system("killall -9 MobilePhone");
	system("killall -9 Phone");
}
%end*/

%hook PHFavoritesCell
- (BOOL)shouldShowContactPhotos {
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
    // conPhotoPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHConPhoto_KEY]) integerValue];
    return [self grabOptionConPhoto:conPhotoPrefs];
}
- (BOOL)shouldShowIconGlyph {
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
    // conGlyphPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHConGlyph_KEY]) integerValue];
    return [self grabOptionConGlyph:conGlyphPrefs];
}
- (BOOL)shouldShowTextLabel {
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
    // conLabelPrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHConLabel_KEY]) integerValue];
    return [self grabOptionConLabel:conLabelPrefs];
}
%new(v@:@@)
- (BOOL)grabOptionConPhoto:(NSInteger)optionConPhoto {
    switch (optionConPhoto) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionConGlyph:(NSInteger)optionConGlyph {
    switch (optionConGlyph) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionConLabel:(NSInteger)optionConLabel {
    switch (optionConLabel) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%end

%hook MobilePhoneApplication
// -(BOOL)showsPhoneVoicemail {
// }
-(BOOL)showsFaceTimeRecents { 
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
 //    ft1Prefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid1_KEY]) integerValue];
    return [self grabOptionFT1:ft1Prefs];
}
-(BOOL)showsFaceTimeAudioRecents { 
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
	// ft2Prefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid2_KEY]) integerValue];
	return [self grabOptionFT2:ft2Prefs];
}
-(BOOL)showsFaceTimeFavorites { 
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
	// ft3Prefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid3_KEY]) integerValue];
	return [self grabOptionFT3:ft3Prefs];
}
-(BOOL)showsFaceTimeAudioFavorites { 
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
	// ft4Prefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid4_KEY]) integerValue];
	return [self grabOptionFT4:ft4Prefs]; 
}
-(BOOL)showsFaceTimeAudio { 
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
	// ft5Prefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid5_KEY]) integerValue];
	return [self grabOptionFT5:ft5Prefs]; 
}
-(BOOL)showsFaceTime { 
	// plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
	// ft6Prefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid6_KEY]) integerValue];
	return [self grabOptionFT6:ft5Prefs]; 
}
%new(v@:@@)
- (BOOL)grabOptionVC:(NSInteger)optionVC {
    switch (optionVC) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFT1:(NSInteger)optionFT1 {
    switch (optionFT1) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFT2:(NSInteger)optionFT2 {
    switch (optionFT2) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFT3:(NSInteger)optionFT3 {
    switch (optionFT3) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFT4:(NSInteger)optionFT4 {
    switch (optionFT4) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFT5:(NSInteger)optionFT5 {
    switch (optionFT5) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (BOOL)grabOptionFT6:(NSInteger)optionFT6 {
    switch (optionFT6) {
	case 0:
	    return NO;
	    break;
	case 1:
	    return YES;
	    break;
	default:
	    break;
    }
}
%end

%hook PHHandsetDialerLCDView
-(void)updateAddAndDeleteButtonForText:(id)arg1 name:(id)arg2 animated:(bool)arg3 {
   if (newButtons) {
       if ([self.numberLabel.text isEqualToString:@""]) {
	       [delSuper setHidden:YES];
	       [addSuper setHidden:YES];
       } else {
	       [delSuper setHidden:NO];
	       [addSuper setHidden:NO];
       }
   } else {
       %orig;
   }
}
-(void)_displayCallout {
	if (editNum) {
		return;
	} else {
		%orig;
	}
}
-(void)_makeCalloutVisible:(BOOL)visible {
	if (editNum) {
		return;
	} else {
		%orig;
	}
}
// -(id)lcdColor { %log; id r = [UIColor redColor]; NSLog(@" = %@", r); return r; }
-(id)initWithFrame:(CGRect)frame forDialerType:(int)dialerType { 
	%log; 
	id r = %orig; 
	if (r) {
      UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
      doubleTap.numberOfTapsRequired = 2; 
      [self addGestureRecognizer:doubleTap];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(copy:) name:@"copyMokh" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paste:) name:@"pasteMokh" object:nil];

	}
	return r; 
}
%new(v@:@@)
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {

  if (![recognizer.view isKindOfClass:[UIView class]]) {

  } else {
    if (editNum) {
      // plist = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
      // stylePrefs = [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHstPrefs_KEY]) integerValue];
      [self grabOption:stylePrefs];
    } else {

    }
  }
}
%new(v@:@@)
-(void)grabOption:(NSInteger)optionNM {
    switch (optionNM) {
	case 0:
	    NSLog(@"**[ PHEnhancer ] ******** UIActionSheet");
	    [self optionUIActionSheet];
	    break;
	case 1:
	    NSLog(@"**[ PHEnhancer ] ******** QBPopupMenu");
	    [self optionQBPopupMenu];
	    break;
	default:
	    break;
    }
}
%new(v@:@@)
- (void)optionUIActionSheet {
  NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
  if ([self.numberLabel.text isEqualToString:@""]) {
	    if ([language isEqualToString:@"ar"]) {
	    	NSString *actionSheetTitle = @"خيارات الرقم"; //Action Sheet Title
			NSString *other2 = @"لصق";
			NSString *cancelTitle = @"الغاء";
			//
			UIActionSheet *actionSheet = [[UIActionSheet alloc]
						      initWithTitle:actionSheetTitle
						      delegate:self
						      cancelButtonTitle:cancelTitle
						      destructiveButtonTitle:nil
						      otherButtonTitles:other2, nil];
			[actionSheet showInView:self];
	    } else {
	    	NSString *actionSheetTitle = @"Number Options"; //Action Sheet Title
			NSString *other2 = @"Paste";
			NSString *cancelTitle = @"Cancel";
			//
			UIActionSheet *actionSheet = [[UIActionSheet alloc]
						      initWithTitle:actionSheetTitle
						      delegate:self
						      cancelButtonTitle:cancelTitle
						      destructiveButtonTitle:nil
						      otherButtonTitles:other2, nil];
			[actionSheet showInView:self];
	    }
    } else {
    	if ([language isEqualToString:@"ar"]) {
    		NSString *actionSheetTitle = @"خيارات الارقم"; //Action Sheet Title
			NSString *other1 = @"نسخ";
			NSString *other2 = @"لصق";
			NSString *other3 = @"تعديل";
			NSString *other4 = @"حذف";
			NSString *cancelTitle = @"الغاء";
			//
			UIActionSheet *actionSheet = [[UIActionSheet alloc]
						      initWithTitle:actionSheetTitle
						      delegate:self
						      cancelButtonTitle:cancelTitle
						      destructiveButtonTitle:nil
						      otherButtonTitles:other1, other2, other3, other4, nil];
			[actionSheet showInView:self];
    	} else {
    		NSString *actionSheetTitle = @"Number Options"; //Action Sheet Title
			NSString *other1 = @"Copy";
			NSString *other2 = @"Paste";
			NSString *other3 = @"Edit";
			NSString *other4 = @"Delete";
			NSString *cancelTitle = @"Cancel";
			//
			UIActionSheet *actionSheet = [[UIActionSheet alloc]
						      initWithTitle:actionSheetTitle
						      delegate:self
						      cancelButtonTitle:cancelTitle
						      destructiveButtonTitle:nil
						      otherButtonTitles:other1, other2, other3, other4, nil];
			[actionSheet showInView:self];
    	}
    }
}

%new(v@:@@)
- (void)optionQBPopupMenu {
  NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
  if ([self.numberLabel.text isEqualToString:@""]) {
  	if ([language isEqualToString:@"ar"]) {
  		QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithTitle:@"لصق" target:self action:@selector(paste:)];
	    NSArray *items = @[item2];
	    
	    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
	    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
	    [popupMenu showInView:[UIWindow keyWindow] targetRect:self.frame animated:YES];
  	} else {
  		QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithTitle:@"Paste" target:self action:@selector(paste:)];
	    NSArray *items = @[item2];
	    
	    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
	    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
	    [popupMenu showInView:[UIWindow keyWindow] targetRect:self.frame animated:YES];
  	}
  } else {
  	if ([language isEqualToString:@"ar"]) {
  		QBPopupMenuItem *item1 = [QBPopupMenuItem itemWithTitle:@"نسخ" target:self action:@selector(copy:)];
	    QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithTitle:@"لصق" target:self action:@selector(paste:)];
	    QBPopupMenuItem *item3 = [QBPopupMenuItem itemWithTitle:@"تعديل" target:self action:@selector(openEditAlert)];
	    // QBPopupMenuItem *item4 = [QBPopupMenuItem itemWithTitle:@"Delete" target:self action:@selector(deleteChars)];
	    NSArray *items = @[item1, item2, item3];
	    
	    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
	    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
	    [popupMenu showInView:[UIWindow keyWindow] targetRect:self.frame animated:YES];
  	} else {
  		QBPopupMenuItem *item1 = [QBPopupMenuItem itemWithTitle:@"Copy" target:self action:@selector(copy:)];
	    QBPopupMenuItem *item2 = [QBPopupMenuItem itemWithTitle:@"Paste" target:self action:@selector(paste:)];
	    QBPopupMenuItem *item3 = [QBPopupMenuItem itemWithTitle:@"Edit" target:self action:@selector(openEditAlert)];
	    // QBPopupMenuItem *item4 = [QBPopupMenuItem itemWithTitle:@"Delete" target:self action:@selector(deleteChars)];
	    NSArray *items = @[item1, item2, item3];
	    
	    QBPopupMenu *popupMenu = [[QBPopupMenu alloc] initWithItems:items];
	    popupMenu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
	    [popupMenu showInView:[UIWindow keyWindow] targetRect:self.frame animated:YES];
  	}
  }
}

%new(v@:@@)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
	NSString *other1 = @"Copy";
	NSString *other2 = @"Paste";
	NSString *other3 = @"Edit";
	NSString *other4 = @"Delete";
	NSString *cancelTitle = @"Cancel";

	NSString *other1AR = @"نسخ";
	NSString *other2AR = @"لقص";
	NSString *other3AR = @"تعديل";
	NSString *other4AR = @"حذف";
	NSString *cancelTitleAR = @"الغاء";

	if  ([buttonTitle isEqualToString:other1]) {
	NSLog(@"Copy pressed --> Copied");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"copyMokh" object: nil];
	}
	if ([buttonTitle isEqualToString:other2]) {
	NSLog(@"Paste pressed");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"pasteMokh" object: nil];
	}
	if ([buttonTitle isEqualToString:other3]) {
	NSLog(@"Edit pressed");
	[self openEditAlert];
	}
	if ([buttonTitle isEqualToString:other4]) {
	    NSLog(@"Delete pressed");
	    [self.numberLabel setText:@""];
	    [self deleteCharacter];
	}
	if ([buttonTitle isEqualToString:cancelTitle]) {
	NSLog(@"Cancel pressed");
	}

	if  ([buttonTitle isEqualToString:other1AR]) {
	NSLog(@"Copy pressed --> Copied");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"copyMokh" object: nil];
	}
	if ([buttonTitle isEqualToString:other2AR]) {
	NSLog(@"Paste pressed");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"pasteMokh" object: nil];
	}
	if ([buttonTitle isEqualToString:other3AR]) {
	NSLog(@"Edit pressed");
	[self openEditAlert];
	}
	if ([buttonTitle isEqualToString:other4AR]) {
	    NSLog(@"Delete pressed");
	    [self.numberLabel setText:@""];
	    [self deleteCharacter];
	}
	if ([buttonTitle isEqualToString:cancelTitleAR]) {
	NSLog(@"Cancel pressed");
	}
}
%new(v@:@@)
- (void)openEditAlert {
	NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
  	if ([language isEqualToString:@"ar"]) {
  		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"تعديل الرقم"
						message:@"يسمح لك بتعديل الرقم المكتوب بالخطأ"
					       delegate:self
				      cancelButtonTitle:@"Done"
				      otherButtonTitles:nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alert textFieldAtIndex:0].text = self.numberLabel.text;
		[alert show];
  	} else {
  		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Number"
						message:@"let you edit your mistyped call number."
					       delegate:self
				      cancelButtonTitle:@"Done"
				      otherButtonTitles:nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alert textFieldAtIndex:0].text = self.numberLabel.text;
		[alert show];
  	}
}
%new(v@:@@)
- (void)deleteChars {
  //[self deleteCharacter];
  [self applyLayoutConstraints];
}

%new(v@:@@)
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"%@", [alertView textFieldAtIndex:0].text);
    self.numberLabel.text = [alertView textFieldAtIndex:0].text;
}
%end

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    system("killall -9 MobilePhone");
    system("killall -9 Phone");


    NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:PREFERENCES_PATH];
    
    editNum =	  [preferences[PREFERENCES_ENABLED_PHeditNum_KEY] boolValue];
    redirectApp = [preferences[PREFERENCES_ENABLED_PHredirectAPP_KEY] boolValue];
    newButtons =     [preferences[PREFERENCES_ENABLED_PHnewButtons_KEY] boolValue];
    noVoKey =	  [preferences[PREFERENCES_ENABLED_PHnoVoKey_KEY] boolValue];
    stylePrefs =   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHstPrefs_KEY]) integerValue];
    tabsPrefs =   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHtabPrefs_KEY]) integerValue];
    vcPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmVoCal_KEY]) integerValue];
    favPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmFavBar_KEY]) integerValue];
    rcnPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmRcnBar_KEY]) integerValue];
    cntPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmCntBar_KEY]) integerValue];
    kbdPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHrmKbdBar_KEY]) integerValue];
    ft1Prefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid1_KEY]) integerValue];
    ft2Prefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid2_KEY]) integerValue];
    ft3Prefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid3_KEY]) integerValue];
    ft4Prefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid4_KEY]) integerValue];
    ft5Prefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid5_KEY]) integerValue];
    ft6Prefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHftInsid6_KEY]) integerValue];

    conPhotoPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHConPhoto_KEY]) integerValue];
    conGlyphPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHConGlyph_KEY]) integerValue];
    conLabelPrefs =	   [((NSNumber*)[plist valueForKey:PREFERENCES_ENABLED_PHConLabel_KEY]) integerValue];
    
}

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PHEnhancerInitPrefs, CFSTR(kPreferencesChanged), NULL, CFNotificationSuspensionBehaviorCoalesce);
    PHEnhancerInitPrefs();
}
