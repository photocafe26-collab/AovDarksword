/*
 * CoreRuntime.m — AovDarksword 1.4
 * Main orchestrator: exploit → sandbox → XPF → find AoV → IL2CPP → ESP loop
 * NO LICENSE KEY / NO API SERVER / NO TrollGameKit
 */

#import "CoreRuntime.h"
#import "task_for_pid.h"
#import "krw.h"
#import "aov_offsets.h"
#import "il2cpp_resolver.h"
#import "grab_kernelcache.h"
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <sys/sysctl.h>

/* Forward declarations for C functions */
extern int kexploit_run(uint64_t *kernel_base, uint64_t *kernel_slide);
extern void kexploit_cleanup(void);
extern int patch_sandbox_ext(void);
extern int mig_bypass_init(uint64_t kernelSlide);
extern int mig_bypass_start(void);

@implementation CoreRuntime {
    dispatch_queue_t _hackQueue;
    BOOL _running;
    BOOL _gameTracking;
    int  _hackTick;
}

+ (instancetype)sharedRuntime {
    static CoreRuntime *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CoreRuntime alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hackQueue = dispatch_queue_create("com.aov.ds.hackloop",
                                            DISPATCH_QUEUE_SERIAL);
        _running = NO;
        _gameTracking = NO;
        _hackTick = 0;
    }
    return self;
}

#pragma mark - Status Update

- (void)_updateStatus:(NSString *)status {
    NSLog(@"%@", status);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(coreRuntime:didUpdateStatus:)]) {
            [self.delegate coreRuntime:self didUpdateStatus:status];
        }
    });
}

- (void)_notifyError:(NSString *)error {
    NSLog(@"[!] %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(coreRuntime:didFailWithError:)]) {
            [self.delegate coreRuntime:self didFailWithError:error];
        }
    });
}

#pragma mark - Process Finding

- (pid_t)findAoVPID {
    pid_t pid = 0;
    char name[256] = {0};

    int ret = find_game_pid(&pid, name, sizeof(name));
    if (ret == 0 && pid > 0) {
        NSLog(@"[+] detected %s (%s) pid=%d proc=0x%llx",
              name, "AoV", pid, (uint64_t)0);
        return pid;
    }
    return 0;
}

- (BOOL)attachToProcess:(pid_t)pid {
    mach_port_t task = MACH_PORT_NULL;
    kern_return_t kr = get_task_port(pid, &task);

    if (kr != KERN_SUCCESS || task == MACH_PORT_NULL) {
        NSLog(@"[ERR] bad task");
        return NO;
    }

    _gamePID = pid;
    _gameTask = task;
    _gameAttached = YES;

    NSLog(@"[+] Game restarted pid=%d", pid);
    return YES;
}

#pragma mark - Hack Loop

- (void)startHackLoop {
    if (_running) return;
    _running = YES;

    dispatch_async(_hackQueue, ^{
        @autoreleasepool {
            @try {
                [self _hackLoopMain];
            } @catch (NSException *e) {
                NSLog(@"[FATAL] HackLoop exception: %s", e.reason.UTF8String);
                NSLog(@"[!] Crash: %@", e);
            }
        }
    });
}

- (void)stopHackLoop {
    _running = NO;
}

- (void)_hackLoopMain {
    /* ===== STEP 1: Kernel Exploit ===== */
    [self _updateStatus:@"[1/4] Running exploit..."];

    uint64_t kernel_base = 0, kernel_slide = 0;
    int ret = kexploit_run(&kernel_base, &kernel_slide);

    if (ret != 0) {
        NSLog(@"[!] Exploit failed: ret=%d kernel_base=0x%llx",
              ret, kernel_base);
        NSLog(@"[!] iOS version may not be supported or exploit was patched.");
        [self _notifyError:@"Startup Failed"];
        return;
    }

    _kernelBase = kernel_base;
    _kernelSlide = kernel_slide;
    _exploitDone = YES;
    NSLog(@"[+] Exploit OK: kernel_base=0x%llx slide=0x%llx",
          kernel_base, kernel_slide);

    /* Verify R/W channel */
    if (!krw_verify(kernel_base)) {
        NSLog(@"[!] R/W channel broken immediately after exploit (g_krw_error=%d)",
              g_krw_error);
        [self _notifyError:@"Startup Failed"];
        return;
    }

    /* ===== STEP 2: Sandbox Patch ===== */
    ret = patch_sandbox_ext();
    if (ret == 0) {
        _sandboxPatched = YES;
        NSLog(@"[+] sandbox patched: rw on /");
    } else {
        NSLog(@"[!] patch_sandbox_ext failed  JSON write may still fail");
    }

    /* ===== STEP 3: XPF (Kernel Symbol Resolution) ===== */
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *kcPath = grab_kernelcache(docsDir);

    if (kcPath) {
        ret = init_xpf(kcPath, kernel_slide);
        if (ret == 0) {
            _xpfReady = YES;
            NSLog(@"[+] XPF OK");
        } else {
            NSLog(@"[!] XPF failed (ret=%d)  physread64_user disabled", ret);
        }
    }

    /* ===== STEP 4: Find AoV Process ===== */
    [self _updateStatus:@"[2/4] Game found"];

    pid_t gamePID = 0;
    int attempt = 0;
    while (_running && gamePID == 0) {
        attempt++;
        NSLog(@"[~] waiting for AOV process (attempt %d)", attempt);
        gamePID = [self findAoVPID];

        if (gamePID == 0) {
            [NSThread sleepForTimeInterval:2.0];
        }
    }

    if (!_running || gamePID == 0) return;

    if (![self attachToProcess:gamePID]) {
        [self _notifyError:@"Startup Failed"];
        return;
    }

    /* ===== STEP 5: IL2CPP Offset Resolution ===== */
    [self _updateStatus:@"[3/4] Unity OK"];

    ret = il2cpp_init(_gameTask, _gamePID);
    if (ret != 0) {
        NSLog(@"[ERR] dyld offset not found");
        [self _notifyError:@"AoV data not found. Run exploit first."];
        return;
    }

    NSLog(@"[AoV] ActorMgr=0x%llx", g_gameState.actorMgrAddr);

    /* ===== STEP 6: ESP Loop ===== */
    [self _updateStatus:@"ESP Active"];
    _gameTracking = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(coreRuntimeDidStartESP:)]) {
            [self.delegate coreRuntimeDidStartESP:self];
        }
    });

    /* Main hack loop */
    while (_running && _gameTracking) {
        @autoreleasepool {
            _hackTick++;

            /* Check if game process still exists */
            if (kill(_gamePID, 0) != 0) {
                NSLog(@"[!] %s pid=%d no longer exists  resetting game tracking",
                      "AoV", _gamePID);
                [self resetGameTracking];

                /* Wait for restart */
                pid_t newPID = 0;
                while (_running && newPID == 0) {
                    newPID = [self findAoVPID];
                    if (newPID == 0) [NSThread sleepForTimeInterval:2.0];
                }

                if (newPID > 0 && _running) {
                    if ([self attachToProcess:newPID]) {
                        il2cpp_init(_gameTask, _gamePID);
                        _gameTracking = YES;
                    }
                }
                continue;
            }

            /* Check R/W health */
            if (g_krw_error != 0) {
                NSLog(@"[FATAL] g_krw_error=%d at tick=%d  closing app",
                      g_krw_error, _hackTick);
                break;
            }

            /* TODO: Read hero/monster data and update ESP view */
            /* This is where mach_vm_read reads from the game process */

            [NSThread sleepForTimeInterval:0.033]; /* ~30fps */
        }
    }

    NSLog(@"[STATE] resetGameTracking  game process died, resetting all caches");
}

- (void)resetGameTracking {
    NSLog(@"[STATE] resetGameTracking  game process died, resetting all caches");
    _gameTracking = NO;
    _gameAttached = NO;

    if (_gameTask != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), _gameTask);
        _gameTask = MACH_PORT_NULL;
    }
    _gamePID = 0;

    /* Reset IL2CPP state */
    memset(&g_gameState, 0, sizeof(g_gameState));
}

@end
