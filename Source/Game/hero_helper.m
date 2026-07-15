#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HeroHelper : NSObject

+ (NSString *)nameForHeroID:(int)heroID;
+ (UIImage *)iconForHeroID:(int)heroID;

@end

@implementation HeroHelper

+ (NSString *)nameForHeroID:(int)heroID {
    return @"Unknown Hero";
}

+ (UIImage *)iconForHeroID:(int)heroID {
    return nil;
}

@end
