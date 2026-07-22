/*
 * overlay_manager.h — AovDarksword 1.4
 */
#import <Foundation/Foundation.h>
#import <mach/mach.h>

typedef NS_ENUM(NSInteger, OverlayMode) {
    OverlayModeKGVN = 0,  /* IOSurface -> remote CALayer */
    OverlayModeSB   = 1,  /* SpringBoard window injection */
    OverlayModeLocal = 2, /* Local UIWindow + SBSAccessibilityWindowHostingController */
};

@interface OverlayManager : NSObject

@property (nonatomic, assign) OverlayMode currentMode;
@property (nonatomic, assign) BOOL overlayActive;

+ (instancetype)sharedManager;

- (void)setupKgvnOverlay:(mach_port_t)gameTask;
- (void)setupSBOverlay:(mach_port_t)sbTask;
- (void)setupLocalWindow;
- (void)clearOverlay;

@end
