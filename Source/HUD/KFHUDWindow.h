/*
 * KFHUDWindow.h — AovDarksword 1.4
 * System-level overlay window with touch passthrough
 */

#import <UIKit/UIKit.h>

@interface KFHUDWindow : UIWindow

@property (nonatomic, assign) BOOL ignoresHitTest;

- (instancetype)initSystemWindow;

@end
