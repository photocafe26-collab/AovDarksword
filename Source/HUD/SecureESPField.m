#import <UIKit/UIKit.h>

@interface SecureESPField : UITextField
@end

@implementation SecureESPField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.secureTextEntry = YES;
    }
    return self;
}

@end
