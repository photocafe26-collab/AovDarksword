/* AudioKeepAlive.m — Silent audio player for background keep-alive */
#import "AudioKeepAlive.h"
#import <AVFAudio/AVFAudio.h>
#import <UIKit/UIKit.h>

@implementation AudioKeepAlive {
    AVAudioPlayer *_kfSilentPlayer;
    NSTimer *_watchdog;
    UIBackgroundTaskIdentifier _bgTask;
}

+ (instancetype)shared {
    static AudioKeepAlive *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[AudioKeepAlive alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bgTask = UIBackgroundTaskInvalid;

        /* Register for interruption notifications */
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(_handleInterruption:)
            name:AVAudioSessionInterruptionNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(_handleMediaServerReset:)
            name:AVAudioSessionMediaServicesWereResetNotification object:nil];
    }
    return self;
}

- (void)startSilentPlayer {
    /* Create 1-second silent audio data */
    NSUInteger sampleRate = 44100;
    NSUInteger channels = 1;
    NSUInteger bytesPerSample = 2;
    NSUInteger dataSize = sampleRate * channels * bytesPerSample;

    NSMutableData *wavData = [NSMutableData data];

    /* WAV header */
    uint32_t fileSize = (uint32_t)(44 + dataSize - 8);
    uint8_t header[44] = {
        'R','I','F','F',
        fileSize & 0xFF, (fileSize >> 8) & 0xFF,
        (fileSize >> 16) & 0xFF, (fileSize >> 24) & 0xFF,
        'W','A','V','E',
        'f','m','t',' ',
        16,0,0,0,     /* chunk size */
        1,0,           /* PCM */
        1,0,           /* mono */
        0x44,0xAC,0,0, /* 44100 */
        0x88,0x58,0x01,0, /* byte rate */
        2,0,           /* block align */
        16,0,          /* bits per sample */
        'd','a','t','a',
        (uint8_t)(dataSize & 0xFF), (uint8_t)((dataSize >> 8) & 0xFF),
        (uint8_t)((dataSize >> 16) & 0xFF), (uint8_t)((dataSize >> 24) & 0xFF),
    };
    [wavData appendBytes:header length:44];

    /* Silent samples */
    uint8_t *silence = calloc(dataSize, 1);
    [wavData appendBytes:silence length:dataSize];
    free(silence);

    NSError *err = nil;
    _kfSilentPlayer = [[AVAudioPlayer alloc] initWithData:wavData error:&err];
    _kfSilentPlayer.numberOfLoops = -1; /* Loop forever */
    _kfSilentPlayer.volume = 0.01;
    [_kfSilentPlayer play];

    NSLog(@"[AUDIO] silent player restarted");

    /* Watchdog timer */
    _watchdog = [NSTimer scheduledTimerWithTimeInterval:10.0
        target:self selector:@selector(_audioWatchdog)
        userInfo:nil repeats:YES];
}

- (void)stopSilentPlayer {
    [_kfSilentPlayer stop];
    _kfSilentPlayer = nil;
    [_watchdog invalidate];
    _watchdog = nil;
}

- (void)_handleInterruption:(NSNotification *)note {
    NSDictionary *info = note.userInfo;
    NSUInteger type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    if (type == AVAudioSessionInterruptionTypeBegan) {
        NSLog(@"[AUDIO] interruption began (game mic/call)  starting bg task");
        _bgTask = [[UIApplication sharedApplication]
            beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self->_bgTask];
            self->_bgTask = UIBackgroundTaskInvalid;
        }];
    } else {
        NSLog(@"[AUDIO] interruption ended  restoring session");
        NSError *err = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&err];
        [_kfSilentPlayer play];

        if (_bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        }
    }
}

- (void)_handleMediaServerReset:(NSNotification *)note {
    NSLog(@"[AUDIO] media server reset  recreating player");
    [self startSilentPlayer];
}

- (void)_audioWatchdog {
    if (!_kfSilentPlayer.isPlaying) {
        NSLog(@"[AUDIO] watchdog: player dead  restoring");
        [_kfSilentPlayer play];
    }
}

@end
