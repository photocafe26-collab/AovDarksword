/* AudioKeepAlive.h */ #import <Foundation/Foundation.h>
@interface AudioKeepAlive : NSObject
+ (instancetype)shared;
- (void)startSilentPlayer;
- (void)stopSilentPlayer;
@end
