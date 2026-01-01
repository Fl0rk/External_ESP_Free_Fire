//
//  MainApplicationDelegate.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import "MainApplicationDelegate.h"
#import "MainApplication.h"
#import "RootViewController.h"

#import "HUDHelper.h"

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    _rootViewController = [[RootViewController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_rootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    __weak MainApplicationDelegate *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong MainApplicationDelegate *strongSelf = weakSelf;
        [strongSelf->_rootViewController reloadMainButtonState];
    });
}

@end
