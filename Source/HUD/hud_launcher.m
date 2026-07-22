/* hud_launcher.m — Spawn HUD process via launchd agent plist */
#import "hud_launcher.h"
#import "aov_offsets.h"
#import <spawn.h>

extern char **environ;

@implementation HUDLauncher

+ (pid_t)spawnHUDProcess:(NSString *)execPath parentPid:(pid_t)ppid {
    /* Create launchd plist */
    NSDictionary *plist = @{
        @"Label": @KF_HUD_BUNDLE_ID,
        @"ProgramArguments": @[execPath],
        @"StandardOutPath": @KF_HUD_STDOUT_LOG,
        @"StandardErrorPath": @KF_HUD_STDERR_LOG,
        @"RunAtLoad": @YES,
    };

    NSString *plistPath = @KF_HUD_AGENT_PLIST;
    [plist writeToFile:plistPath atomically:YES];

    /* Copy to LaunchAgents */
    NSString *agentPath = [NSString stringWithFormat:@"%s/%s.plist",
        KF_LAUNCH_AGENTS_DIR, KF_HUD_BUNDLE_ID];

    [[NSFileManager defaultManager] createDirectoryAtPath:@KF_LAUNCH_AGENTS_DIR
                              withIntermediateDirectories:YES attributes:nil error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:plistPath toPath:agentPath error:nil];

    /* launchctl load */
    pid_t lpid = 0;
    char *argv[] = { "/bin/launchctl", "load", (char *)agentPath.UTF8String, NULL };
    int rc = posix_spawn(&lpid, "/bin/launchctl", NULL, NULL, argv, environ);

    if (rc == 0) {
        NSLog(@"[KFUN][HUD] launchctl load submitted (lpid=%d)", lpid);
        NSLog(@"[KFUN][HUD] spawned HUD process pid=%d", lpid);
    } else {
        NSLog(@"[KFUN][HUD] launchctl spawn failed rc=%d", rc);
    }

    return lpid;
}

@end
