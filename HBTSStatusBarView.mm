#include <substrate.h> // ?!!?
#import "HBTSStatusBarView.h"
#import "HBTSStatusBarWindow.h"
#import <UIKit/UIApplication+Private.h>
#import <UIKit/UIImage+Private.h>
#import <UIKit/UIKitModernUI.h>
#import <UIKit/UIStatusBar.h>
#import <UIKit/UIStatusBarForegroundView.h>
#import <UIKit/UIStatusBarForegroundStyleAttributes.h>
#import <version.h>
#include <notify.h>

#define IS_RETINA ([UIScreen mainScreen].scale > 1)
#define IS_MODERN IS_IOS_OR_NEWER(iOS_7_0)
;

static CGFloat const kHBTSStatusBarFontSize = IS_MODERN ? 12.f : 14.f;

@interface HBTSStatusBarView () {
	UIView *_containerView;
	UILabel *_typeLabel;
	UILabel *_contactLabel;
	UIImageView *_iconImageView;

	HBTSStatusBarType _type;
}

@end

@implementation HBTSStatusBarView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.clipsToBounds = NO;

		_containerView = [[UIView alloc] initWithFrame:self.frame];
		_containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:_containerView];

		_iconImageView = [[[UIImageView alloc] initWithImage:[UIImage kitImageNamed:@"WhiteOnBlackEtch_TypeStatus"]] autorelease];
		_iconImageView.center = CGPointMake(_iconImageView.center.x, (self.frame.size.height - 2.f) / 2);
		_iconImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[_containerView addSubview:_iconImageView];

		CGFloat top = IS_RETINA ? -0.5f : -1.f;

		_typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_iconImageView.frame.size.width + 4.f, top, 0, self.frame.size.height)];
		_typeLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_typeLabel.font = [UIFont boldSystemFontOfSize:kHBTSStatusBarFontSize];
		_typeLabel.backgroundColor = [UIColor clearColor];
		_typeLabel.textColor = [UIColor whiteColor];
		[_containerView addSubview:_typeLabel];

		_contactLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, top, 0, self.frame.size.height)];
		_contactLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_contactLabel.font = [UIFont systemFontOfSize:kHBTSStatusBarFontSize];
		_contactLabel.backgroundColor = [UIColor clearColor];
		_contactLabel.textColor = [UIColor whiteColor];
		[_containerView addSubview:_contactLabel];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGRect typeFrame = _typeLabel.frame;
	typeFrame.size.width = [_typeLabel sizeThatFits:self.frame.size].width;
	_typeLabel.frame = typeFrame;

	CGRect labelFrame = _contactLabel.frame;
	labelFrame.origin.x = typeFrame.origin.x + typeFrame.size.width + 4.f;
	labelFrame.size.width = [_contactLabel sizeThatFits:self.frame.size].width;
	_contactLabel.frame = labelFrame;

	CGRect containerFrame = _containerView.frame;
	containerFrame.size.width = labelFrame.origin.x + labelFrame.size.width;
	_containerView.frame = containerFrame;

	_containerView.center = CGPointMake(self.frame.size.width / 2, _containerView.center.y);
}

#pragma mark - Adapting UI

- (void)_updateForCurrentStatusBarStyle {
	static UIImage *TypingImage;
	static UIImage *TypingImageWhite;
	static UIImage *ReadImage;
	static UIImage *ReadImageWhite;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		if (IS_MODERN) {
			UIImage *typingImage = [[UIImage kitImageNamed:@"Black_TypeStatus"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			UIImage *readImage = [[UIImage kitImageNamed:@"Black_TypeStatusRead"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

			TypingImage = [typingImage retain];
			ReadImage = [readImage retain];
		} else {
			TypingImage = [[UIImage kitImageNamed:@"WhiteOnBlackEtch_TypeStatus"] retain];
			ReadImage = [[UIImage kitImageNamed:@"WhiteOnBlackEtch_TypeStatusRead"] retain];
		}

		if (IS_IOS_OR_OLDER(iOS_5_1) && !IS_IPAD) {
			TypingImageWhite = [[UIImage kitImageNamed:@"ColorOnGrayShadow_TypeStatus"] retain];
			ReadImageWhite = [[UIImage kitImageNamed:@"ColorOnGrayShadow_TypeStatusRead"] retain];
		}
	});

	UIColor *textColor;
	UIColor *shadowColor;
	CGSize shadowOffset;
	BOOL isWhite = NO;

	if (IS_MODERN) {
		UIStatusBarForegroundView *foregroundView = MSHookIvar<UIStatusBarForegroundView *>([UIApplication sharedApplication].statusBar, "_foregroundView");
		textColor = MSHookIvar<UIColor *>(foregroundView.foregroundStyle, "_tintColor");
	} else {
		if (!IS_IOS_OR_NEWER(iOS_6_0) && !IS_IPAD && [UIApplication sharedApplication].statusBarStyle == UIStatusBarStyleDefault) {
			textColor = [UIColor blackColor];
			shadowColor = [UIColor whiteColor];
			shadowOffset = CGSizeMake(0, 1.f);
			isWhite = YES;
		} else {
			textColor = [UIColor whiteColor];
			shadowColor = [UIColor colorWithWhite:0 alpha:0.5f];
			shadowOffset = CGSizeMake(0, -1.f);
		}
	}

	switch (_type) {
		case HBTSStatusBarTypeTyping:
			_iconImageView.image = isWhite && TypingImageWhite ? TypingImageWhite : TypingImage;
			break;

		case HBTSStatusBarTypeRead:
			_iconImageView.image = isWhite && ReadImageWhite ? ReadImageWhite : ReadImage;
			break;

		case HBTSStatusBarTypeTypingEnded:
			break;
	}

	_typeLabel.textColor = textColor;
	_contactLabel.textColor = textColor;

	if (IS_MODERN) {
		_iconImageView.tintColor = textColor;
	} else {
		_typeLabel.shadowColor = shadowColor;
		_contactLabel.shadowColor = shadowColor;

		_typeLabel.shadowOffset = shadowOffset;
		_contactLabel.shadowOffset = shadowOffset;
	}
}

#pragma mark - Show/hide

- (void)setType:(HBTSStatusBarType)type name:(NSString *)name {
	if (type == HBTSStatusBarTypeTypingEnded) {
		return;
	}

	_type = type;

	switch (type) {
		case HBTSStatusBarTypeTyping:
			_typeLabel.text = L18N(@"Typing:");
			break;

		case HBTSStatusBarTypeRead:
			_typeLabel.text = L18N(@"Read:");
			break;

		case HBTSStatusBarTypeTypingEnded:
			break;
	}

	_contactLabel.text = name;

	[self _updateForCurrentStatusBarStyle];
	[self layoutSubviews];
}

#pragma mark - Memory management

- (void)dealloc {
	[_containerView release];
	[_typeLabel release];
	[_contactLabel release];
	[_iconImageView release];

	[super dealloc];
}

@end
