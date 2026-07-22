/* ContentLayer.m */
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

@interface ContentLayer : CALayer
@end

@implementation ContentLayer
+ (id)defaultActionForKey:(NSString *)event { return [NSNull null]; }
- (id)actionForKey:(NSString *)event { return [NSNull null]; }
@end
