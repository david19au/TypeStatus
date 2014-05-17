#import "Global.h"
#import "HBTSStatusBarWindow.h"

%ctor {
	prefsBundle = [[NSBundle bundleWithPath:@"/Library/PreferenceBundles/TypeStatus.bundle"] retain];
}

#pragma mark - Preferences management

void HBTSLoadPrefs() {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/ws.hbang.typestatus.plist"];

#if SPRINGBOARD || IMAGENT
	typingHideInMessages = GET_BOOL(@"HideInMessages", YES);
	readHideInMessages = GET_BOOL(@"HideReadInMessages", YES);
	typingIcon = GET_BOOL(@"TypingIcon", NO);
	typingStatus = GET_BOOL(@"TypingStatus", YES);
	readStatus = GET_BOOL(@"ReadStatus", YES);
#endif

	typingTimeout = GET_BOOL(@"TypingTimeout", NO);
	overlayDuration = GET_FLOAT(@"OverlayDuration", 5.f);

	if (firstLoad) {
		firstLoad = NO;
	} else {
#if IMAGENT
		if (!typingIcon || !typingStatus) {
			typingIndicators = 1;
			HBTSTypingEnded();
		} else if (!readStatus) {
			HBTSPostMessage(HBTSStatusBarTypeRead, nil, NO);
		}
#endif
	}

#if !IMAGENT && !SPRINGBOARD
	if (overlayWindow) {
		overlayWindow.shouldSlide = GET_BOOL(@"OverlaySlide", YES);
		overlayWindow.shouldFade = GET_BOOL(@"OverlayFade", YES);
	}
#endif
}
