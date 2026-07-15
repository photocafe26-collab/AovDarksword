#import <UIKit/UIKit.h>

@interface KFHUDESPView : UIView
@end

@implementation KFHUDESPView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateESP)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)updateESP {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // ESP rendering logic: boxes, lines, HP bars, distance, names
}

@end
