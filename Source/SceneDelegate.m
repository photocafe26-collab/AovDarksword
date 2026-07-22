/*
 * SceneDelegate.m — AovDarksword 1.4
 */
#import "SceneDelegate.h"
#import "ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    NSLog(@"[STATE] %ld", (long)UIApplication.sharedApplication.applicationState);
}

- (void)sceneWillResignActive:(UIScene *)scene {}
- (void)sceneDidEnterBackground:(UIScene *)scene {}
- (void)sceneWillEnterForeground:(UIScene *)scene {}

@end
