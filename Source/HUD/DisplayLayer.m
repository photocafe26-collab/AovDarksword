/* DisplayLayer.h */ #import <QuartzCore/QuartzCore.h>
@interface DisplayLayer : CALayer @end

/* DisplayLayer.m */
#import "DisplayLayer.h"
@implementation DisplayLayer
+ (id)defaultActionForKey:(NSString *)event { return [NSNull null]; }
- (id)actionForKey:(NSString *)event { return [NSNull null]; }
@end
