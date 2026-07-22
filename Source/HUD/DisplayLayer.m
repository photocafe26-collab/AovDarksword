/* DisplayLayer.m */
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

@interface DisplayLayer : CALayer
@end

@implementation DisplayLayer
+ (id)defaultActionForKey:(NSString *)event { return [NSNull null]; }
- (id)actionForKey:(NSString *)event { return [NSNull null]; }
@end
