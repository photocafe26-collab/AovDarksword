/*
 * CoreRuntime.h — AovDarksword 1.4
 * Main exploit orchestrator
 */

#import <Foundation/Foundation.h>
#import <mach/mach.h>

@protocol CoreRuntimeDelegate <NSObject>
@optional
- (void)coreRuntime:(id)runtime didUpdateStatus:(NSString *)status;
- (void)coreRuntime:(id)runtime didFindGame:(NSString *)name pid:(pid_t)pid;
- (void)coreRuntime:(id)runtime didFailWithError:(NSString *)error;
- (void)coreRuntimeDidStartESP:(id)runtime;
@end

@interface CoreRuntime : NSObject

@property (nonatomic, weak) id<CoreRuntimeDelegate> delegate;
@property (nonatomic, assign, readonly) pid_t gamePID;
@property (nonatomic, assign, readonly) mach_port_t gameTask;
@property (nonatomic, assign, readonly) uint64_t kernelBase;
@property (nonatomic, assign, readonly) uint64_t kernelSlide;
@property (nonatomic, assign, readonly) BOOL exploitDone;
@property (nonatomic, assign, readonly) BOOL sandboxPatched;
@property (nonatomic, assign, readonly) BOOL xpfReady;
@property (nonatomic, assign, readonly) BOOL gameAttached;

+ (instancetype)sharedRuntime;

- (void)startHackLoop;
- (void)stopHackLoop;
- (void)resetGameTracking;

- (pid_t)findAoVPID;
- (BOOL)attachToProcess:(pid_t)pid;

@end
