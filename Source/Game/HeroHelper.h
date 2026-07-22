/*
 * HeroHelper.h — AovDarksword 1.4
 * Hero name/icon database lookup
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HeroHelper : NSObject

+ (NSString *)nameForHeroID:(int)heroID;
+ (UIImage *)iconForHeroID:(int)heroID;

@end
