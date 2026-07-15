#import <Foundation/Foundation.h>

@interface CoreRuntime : NSObject

+ (instancetype)sharedRuntime;

- (pid_t)findAoVPID;
- (BOOL)attachToProcess:(pid_t)pid;
- (void)startHackLoop;

@end
