/* hud_launcher.h */ #import <Foundation/Foundation.h>
@interface HUDLauncher : NSObject
+ (pid_t)spawnHUDProcess:(NSString *)execPath parentPid:(pid_t)ppid;
@end
