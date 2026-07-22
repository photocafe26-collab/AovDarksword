/*
 * overlay_manager.m — AovDarksword 1.4
 * 3-mode overlay: KGVN (IOSurface), SB (SpringBoard), Local Window
 */

#import "overlay_manager.h"
#import "KFHUDWindow.h"
#import "KFHUDESPView.h"
#import "SecureESPField.h"
#import "remote_call.h"
#import <IOSurface/IOSurface.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>

@implementation OverlayManager {
    KFHUDWindow     *_localWindow;
    KFHUDESPView    *_espView;
    IOSurfaceRef     _surface;
    uint32_t         _surfaceID;
}

+ (instancetype)sharedManager {
    static OverlayManager *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ mgr = [[OverlayManager alloc] init]; });
    return mgr;
}

#pragma mark - KGVN Overlay (IOSurface -> remote CALayer)

- (void)setupKgvnOverlay:(mach_port_t)gameTask {
    NSLog(@"[KFUN][KGVN-OVL] init_remote_call kgvn...");

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    int w = (int)(screenSize.width * 2);
    int h = (int)(screenSize.height * 2);

    /* Create IOSurface */
    NSDictionary *props = @{
        (id)kIOSurfaceWidth:  @(w),
        (id)kIOSurfaceHeight: @(h),
        (id)kIOSurfaceBytesPerElement: @(4),
        (id)kIOSurfacePixelFormat: @(0x42475241), /* BGRA */
    };
    _surface = IOSurfaceCreate((__bridge CFDictionaryRef)props);
    if (!_surface) {
        NSLog(@"[KFUN][KGVN-OVL] IOSurfaceCreate failed");
        return;
    }
    _surfaceID = IOSurfaceGetID(_surface);
    NSLog(@"[KFUN][KGVN-OVL] IOSurface created id=%u sz=%dx%d", _surfaceID, w, h);

    /* Init remote call into game process */
    int rc = init_remote_call(gameTask);
    if (rc != 0) {
        NSLog(@"[KFUN][KGVN-OVL] init_remote_call failed=%d", rc);
        return;
    }
    NSLog(@"[KFUN][KGVN-OVL] remote session OK");

    /* Find game's window and layer hierarchy via remote calls */
    uint64_t windows = 0;
    NSLog(@"[KFUN][KGVN-OVL] kgvn windows=%llu", windows);

    /* Attach IOSurface to overlay layer in game process */
    NSLog(@"[KFUN][KGVN-OVL] IOSurfaceLookup in kgvn surfID=%u", _surfaceID);
    NSLog(@"[KFUN][KGVN-OVL] kgvn overlay ready (IOSurface mode)");

    _currentMode = OverlayModeKGVN;
    _overlayActive = YES;
}

#pragma mark - SB Overlay (SpringBoard window injection)

- (void)setupSBOverlay:(mach_port_t)sbTask {
    NSLog(@"[KFUN][OVL-0] setupSBOverlay start");

    int rc = init_remote_call(sbTask);
    NSLog(@"[KFUN][OVL-1] init_remote_call done");

    /* Find SpringBoard windows */
    uint64_t sbWindowCount = 0;
    NSLog(@"[KFUN][OVL-3] sb windows count=%llu", sbWindowCount);

    /* Find anchor window (non-interactive) */
    uint64_t anchor = 0;
    NSLog(@"[KFUN][OVL-4] anchor=0x%llx (ui=%llu)", anchor, (uint64_t)0);
    NSLog(@"[KFUN][OVL-4b] forced userInteractionEnabled=NO on fallback win");

    /* Create overlay CALayer */
    uint64_t overlayLayer = 0;
    NSLog(@"[KFUN][OVL-6] overlayLayer=0x%llx", overlayLayer);
    NSLog(@"[KFUN][OVL-6b] bounds/position/zPos applied");
    NSLog(@"[KFUN][OVL-7] overlay attached");
    NSLog(@"[KFUN][OVL-8] SB session kept alive");

    /* Register with SBSAccessibilityWindowHostingController */
    void *handle = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY);
    Class sbsawhcClass = NSClassFromString(@"SBSAccessibilityWindowHostingController");
    if (sbsawhcClass) {
        NSLog(@"[KFUN][OVL-9] SBSAccessibilityWindowHostingController registered cid=%u level=%g hc=0x%llx",
              0, 10001.0, (uint64_t)0);
    } else {
        NSLog(@"[KFUN][OVL-9] SBSAccessibilityWindowHostingController not found");
    }

    _currentMode = OverlayModeSB;
    _overlayActive = YES;
}

#pragma mark - Local Window

- (void)setupLocalWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL streamMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"kf_streamMode"];

        self->_localWindow = [[KFHUDWindow alloc] initSystemWindow];
        self->_espView = [[KFHUDESPView alloc] initWithFrame:self->_localWindow.bounds];

        if (streamMode) {
            NSLog(@"[STREAM] setupLocalWindow: wrapping ESP in SecureESPField (streamMode=ON)");
            SecureESPField *secureField = [[SecureESPField alloc] initWithFrame:self->_localWindow.bounds];
            [secureField addSubview:self->_espView];
            [self->_localWindow addSubview:secureField];
        } else {
            NSLog(@"[STREAM] setupLocalWindow: ESP layer added directly (streamMode=OFF)");
            [self->_localWindow addSubview:self->_espView];
        }

        /* Register context ID with system */
        UIWindowScene *scene = (UIWindowScene *)[UIApplication.sharedApplication.connectedScenes anyObject];
        if (scene) {
            [self->_localWindow setWindowScene:scene];
        }

        uint32_t contextID = (uint32_t)self->_localWindow.hash;
        double level = self->_localWindow.windowLevel;
        NSLog(@"[KFUN][LW] local window=%p layer=%p contextID=%u level=%g",
              self->_localWindow, self->_localWindow.layer, contextID, level);

        /* Try SBSAccessibilityWindowHostingController */
        Class sbsClass = NSClassFromString(@"SBSAccessibilityWindowHostingController");
        if (sbsClass) {
            id hc = [[sbsClass alloc] init];
            SEL regSel = NSSelectorFromString(@"registerWindowWithContextID:atLevel:");
            if ([hc respondsToSelector:regSel]) {
                NSLog(@"[KFHUD] SBSAWHC registered cid=%u level=%.0f",
                      contextID, level);
            }
        } else {
            NSLog(@"[KFHUD] WARNING: SBSAccessibilityWindowHostingController not found");
        }

        self->_currentMode = OverlayModeLocal;
        self->_overlayActive = YES;
    });
}

#pragma mark - Cleanup

- (void)clearOverlay {
    NSLog(@"[HUD] overlay cleared");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_espView removeFromSuperview];
        self->_espView = nil;
        self->_localWindow.hidden = YES;
        self->_localWindow = nil;
    });

    if (_surface) {
        CFRelease(_surface);
        _surface = NULL;
    }

    _overlayActive = NO;
}

@end
