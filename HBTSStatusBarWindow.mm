//#import "Global.h"

typedef NS_ENUM(NSUInteger, HBTSStatusBarType) {
	HBTSStatusBarTypeTyping,
	HBTSStatusBarTypeTypingEnded,
	HBTSStatusBarTypeRead
};


#import "HBTSStatusBarWindow.h"
#import "HBTSStatusBarView.h"
#import <UIKit/UIApplication+Private.h>
#import <UIKit/UIStatusBarForegroundView.h>
#import <UIKit/UIWindow+Private.h>
#include <notify.h>
#include <substrate.h>

@implementation HBTSStatusBarWindow {
	BOOL _isAnimating;
	BOOL _isVisible;
	NSTimer *_timer;
}

#pragma mark - UIView

- (instancetype)init {
	self = [super init];

	if (self) {
		self.windowLevel = UIWindowLevelStatusBar;
		self.userInteractionEnabled = NO;

		_statusBarView = [[HBTSStatusBarView alloc] initWithFrame:self.frame];
		_statusBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_statusBarView];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChange) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
		[self statusBarDidChange];

	}

	return self;
}

#pragma mark - Show/hide

- (void)showWithType:(HBTSStatusBarType)type name:(NSString *)name timeout:(NSTimeInterval)timeout {
	if (type == HBTSStatusBarTypeTypingEnded) {
		[self hide];
		return;
	}

	if (_timer || _isAnimating || _isVisible) {
		return;
	}

	self.windowLevel = [UIApplication sharedApplication].isLocked ? UIWindowLevelStatusBarLockScreen : UIWindowLevelStatusBar;

	_isAnimating = YES;
	_isVisible = YES;

	[_statusBarView setType:type name:name];

	CGRect frame = self.frame;
	frame.origin.y = -frame.size.height;
	self.frame = frame;

	self.alpha = 0;
	self.hidden = NO;

	UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>([UIApplication sharedApplication].statusBar, "_foregroundView");
	foregroundView.clipsToBounds = YES;

	void (^animationBlock)() = ^{
		CGRect frame = self.frame;
		frame.origin.y = 0;
		self.frame = frame;

		CGRect foregroundFrame = foregroundView.frame;
		foregroundFrame.origin.y = frame.size.height;
		foregroundFrame.size.height = 0;
		foregroundView.frame = foregroundFrame;

		self.alpha = foregroundView.alpha;
		foregroundView.alpha = 0;
	};

	void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
		_isAnimating = NO;
		_timer = [[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(hide) userInfo:nil repeats:NO] retain];
	};

	if (_shouldSlide || _shouldFade) {
		[UIView animateWithDuration:kHBTSStatusBarAnimationDuration animations:animationBlock completion:completionBlock];
	} else {
		animationBlock();
		completionBlock(YES);
	}
}

- (void)hide {
	if (!_timer || _isAnimating || !_isVisible) {
		return;
	}

	_isAnimating = YES;

	[_timer invalidate];
	[_timer release];
	_timer = nil;

	UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>([UIApplication sharedApplication].statusBar, "_foregroundView");

	void (^animationBlock)() = ^{
		if (_shouldSlide) {
			CGRect frame = self.frame;
			frame.origin.y = -frame.size.height;
			self.frame = frame;
		}

		CGRect foregroundFrame = foregroundView.frame;
		foregroundFrame.origin.y = 0;
		foregroundFrame.size.height = self.frame.size.height;
		foregroundView.frame = foregroundFrame;

		foregroundView.alpha = self.alpha;
		self.alpha = 0;
	};

	void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
		self.hidden = YES;
		foregroundView.clipsToBounds = NO;

		_isAnimating = NO;
		_isVisible = NO;

		if (IN_SPRINGBOARD) {
			notify_post("ws.hbang.typestatus/OverlayDidHide");
		}
	};

	if (_shouldSlide || _shouldFade) {
		[UIView animateWithDuration:kHBTSStatusBarAnimationDuration animations:animationBlock completion:completionBlock];
	} else {
		animationBlock();
		completionBlock(YES);
	}
}

#pragma mark - Rotation

- (void)statusBarDidChange {
	self.frame = [UIApplication sharedApplication].statusBarFrame;

	CGFloat angle = 0;

	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
		default:
			angle = 0;
			break;

		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			break;

		case UIInterfaceOrientationLandscapeLeft:
			angle = -M_PI_2;
			break;

		case UIInterfaceOrientationLandscapeRight:
			angle = M_PI_2;
			break;
	}

	self.transform = CGAffineTransformMakeRotation(angle);

	[_statusBarView setNeedsDisplay];
}

#pragma mark - Memory management

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_timer release];

	[super dealloc];
}

@end
