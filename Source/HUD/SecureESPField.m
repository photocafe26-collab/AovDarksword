/*
 * SecureESPField.m — AovDarksword 1.4
 * UITextField subclass with _shouldCreateContextAsSecure for anti-recording
 */
#import "SecureESPField.h"

@implementation SecureESPField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.secureTextEntry = YES;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

/* Private API: prevents screen recording/screenshot of this view's content */
- (BOOL)_shouldCreateContextAsSecure {
    return YES;
}

/* Prevent cursor and text selection */
- (CGRect)caretRectForPosition:(UITextPosition *)position {
    return CGRectZero;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range {
    return @[];
}

@end
