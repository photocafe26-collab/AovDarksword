/* KFHUDAppDelegate.m — HUD process delegate */
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface KFHUDAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation KFHUDAppDelegate

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    NSLog(@"[KFHUD] HUD process starting (parent pid=%d)", getppid());

    /* Write PID file */
    NSString *pidStr = [NSString stringWithFormat:@"%d", getpid()];
    [pidStr writeToFile:@"/tmp/kf_hud.pid" atomically:YES
               encoding:NSUTF8StringEncoding error:nil];

    /* Setup window */
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelAlert + 200;

    /* Register with SpringBoard */
    Class sbsClass = NSClassFromString(@"SBSAccessibilityWindowHostingController");
    if (sbsClass) {
        uint32_t cid = (uint32_t)self.window.hash;
        NSLog(@"[KFHUD] SBSAWHC registered cid=%u level=%.0f", cid, self.window.windowLevel);
    }

    /* Start display link at 15Hz for HUD */
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self
                                                      selector:@selector(_hudTick:)];
    link.preferredFramesPerSecond = 15;
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    NSLog(@"[KFHUD] display link started at 15Hz");

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)_hudTick:(CADisplayLink *)link {
    /* Read shared memory and update HUD ESP view */
}

@end
