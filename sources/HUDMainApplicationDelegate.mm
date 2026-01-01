//
//  HUDMainApplicationDelegate.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//  Updated to force landscape window and embed only ESP view into container (2025).
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "HUDMainApplicationDelegate.h"
#import "HUDMainWindow.h"

#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"

#import "../esp/drawing_view/esp.h"
#import "UIView+SecureView.h"


@interface HUDLandscapeContainerViewController : UIViewController
@end

@implementation HUDLandscapeContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

@end

#pragma mark - HUDMainApplicationDelegate

@implementation HUDMainApplicationDelegate {
    SBSAccessibilityWindowHostingController *_windowHostingController;
}

- (instancetype)init
{
    if (self = [super init])
    {
        //log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]");
    }
    return self;
}

- (UIInterfaceOrientation)currentInterfaceOrientation {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                if (ws.activationState == UISceneActivationStateForegroundActive ||
                    ws.activationState == UISceneActivationStateForegroundInactive) {
                    return ws.interfaceOrientation;
                }
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIInterfaceOrientation sb = [UIApplication sharedApplication].statusBarOrientation;
#pragma clang diagnostic pop
    if (sb != UIInterfaceOrientationUnknown) {
        return sb;
    }

    UIDeviceOrientation dev = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(dev)) {
        return (dev == UIDeviceOrientationLandscapeLeft) ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationLandscapeLeft;
    }
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions
{
    //log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);

    HUDLandscapeContainerViewController *container = [[HUDLandscapeContainerViewController alloc] init];

    ESP_View *espView = [[ESP_View alloc] initWithFrame:CGRectZero];
    espView.translatesAutoresizingMaskIntoConstraints = NO;
    espView.backgroundColor = [UIColor clearColor];
    espView.userInteractionEnabled = NO;
    [espView hideViewFromCapture:YES];
    
    
    UIView *containerView = container.view;
    [containerView addSubview:espView];

    [NSLayoutConstraint activateConstraints:@[
        [espView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [espView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [espView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [espView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
    ]];

    self.window = [[HUDMainWindow alloc] initWithFrame:CGRectZero];
    [self.window setRootViewController:container];

    UIInterfaceOrientation curOrientation = [self currentInterfaceOrientation];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (UIInterfaceOrientationIsLandscape(curOrientation)) {
        screenBounds = CGRectMake(0, 0, CGRectGetHeight(screenBounds), CGRectGetWidth(screenBounds));
    }

    [self.window setFrame:screenBounds];
    self.window.center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds));

    SEL setOrientSel = NSSelectorFromString(@"_setInterfaceOrientation:");
    if ([self.window respondsToSelector:setOrientSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSMethodSignature *sig = [self.window methodSignatureForSelector:setOrientSel];
        if (sig) {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setSelector:setOrientSel];
            [inv setTarget:self.window];
            NSInteger orientVal = (NSInteger)curOrientation;
            [inv setArgument:&orientVal atIndex:2];
            [inv invoke];
        }
#pragma clang diagnostic pop
    }

    if (UIInterfaceOrientationIsLandscape(curOrientation)) {
        CGAffineTransform rot = (curOrientation == UIInterfaceOrientationLandscapeLeft)
            ? CGAffineTransformMakeRotation(-M_PI_2)
            : CGAffineTransformMakeRotation(M_PI_2);

        self.window.transform = rot;
        self.window.frame = screenBounds;
    } else {
        self.window.transform = CGAffineTransformIdentity;
        self.window.frame = screenBounds;
    }

    self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    NSLog(@"andrdevv [self.window] initWithFrame: %@", NSStringFromCGRect(self.window.frame));

    [self.window setWindowLevel:10000010.0];
    [self.window setHidden:NO];
    [self.window makeKeyAndVisible];

    [containerView setNeedsLayout];
    [containerView layoutIfNeeded];

    espView.frame = containerView.bounds;

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [self.window _contextId];
    double windowLevel = [self.window windowLevel];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&_contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];
#pragma clang diagnostic pop

    return YES;
}

@end
