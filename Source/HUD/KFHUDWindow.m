/*
 * KFHUDWindow.m — AovDarksword 1.4
 * System-level overlay window, passes all touches through
 */

#import "KFHUDWindow.h"

@implementation KFHUDWindow

- (instancetype)initSystemWindow {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self = [super initWithFrame:screenBounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert + 100;
        self.hidden = NO;
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        _ignoresHitTest = YES;
    }
    return self;
}

- (BOOL)_isSystemWindow {
    return YES;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (_ignoresHitTest) {
        return nil; /* Pass all touches through */
    }
    return [super hitTest:point withEvent:event];
}

- (BOOL)_ignoresHitTest {
    return _ignoresHitTest;
}

@end
