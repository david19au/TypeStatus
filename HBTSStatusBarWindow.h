@class HBTSStatusBarView;

static NSTimeInterval const kHBTSStatusBarAnimationDuration = 0.25;
static CGFloat const kHBTSStatusBarAnimationDamping = 1.f;
static CGFloat const kHBTSStatusBarAnimationVelocity = 1.f;

@interface HBTSStatusBarWindow : UIWindow

- (void)showWithType:(HBTSStatusBarType)type name:(NSString *)name timeout:(NSTimeInterval)timeout;
- (void)hide;

@property (nonatomic, retain) HBTSStatusBarView *statusBarView;
@property (copy) void (^completion)();

@property BOOL shouldSlide;
@property BOOL shouldFade;

@end
