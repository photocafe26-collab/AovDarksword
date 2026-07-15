#import "CoreRuntime.h"
#import "task_for_pid.h"
#import <mach/mach.h>

@implementation CoreRuntime

+ (instancetype)sharedRuntime {
    static CoreRuntime *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CoreRuntime alloc] init];
    });
    return shared;
}

- (pid_t)findAoVPID {
    // Dummy implementation for finding PID
    pid_t pid = 0;
    find_game_pid("com.garena.game.kgvn", &pid);
    return pid;
}

- (BOOL)attachToProcess:(pid_t)pid {
    mach_port_t task = MACH_PORT_NULL;
    kern_return_t kr = get_task_port(pid, &task);
    if (kr == KERN_SUCCESS && task != MACH_PORT_NULL) {
        NSLog(@"Attached to PID %d, task port: %x", pid, task);
        return YES;
    }
    NSLog(@"Failed to attach to PID %d", pid);
    return NO;
}

- (void)startHackLoop {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        pid_t pid = [self findAoVPID];
        if (pid > 0) {
            if ([self attachToProcess:pid]) {
                // Initialize exploit, XPF, resolve offsets, start ESP loop
                NSLog(@"Starting exploit chain...");
            }
        } else {
            NSLog(@"AoV process not found.");
        }
    });
}

@end
