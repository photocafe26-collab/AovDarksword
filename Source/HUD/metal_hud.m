/* metal_hud.m — MobileGestalt plist manipulation for Metal HUD */
#import "metal_hud.h"

#define MOBILEGESTALT_PLIST @"/var/containers/Shared/SystemGroup/" \
    @"systemgroup.com.apple.mobilegestaltcache/Library/Caches/" \
    @"com.apple.MobileGestalt.plist"
#define METAL_HUD_KEY @"EqrsVvjcYDdxHBiQmGhAWw"

@implementation MetalHUD

+ (BOOL)isEnabled {
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:MOBILEGESTALT_PLIST];
    if (!plist) {
        NSLog(@"[KFUN][MetalHUD] failed to read MobileGestalt plist");
        return NO;
    }
    NSDictionary *cache = plist[@"CacheExtra"];
    if (!cache) {
        NSLog(@"[MetalHUD] CacheExtra key not found");
        return NO;
    }
    return [cache[METAL_HUD_KEY] boolValue];
}

+ (BOOL)setEnabled:(BOOL)enabled {
    NSMutableDictionary *plist = [NSMutableDictionary
        dictionaryWithContentsOfFile:MOBILEGESTALT_PLIST];
    if (!plist) {
        NSLog(@"[MetalHUD] Cannot read plist (sandbox not patched?)");
        return NO;
    }

    NSMutableDictionary *cache = [plist[@"CacheExtra"] mutableCopy];
    if (!cache) {
        NSLog(@"[MetalHUD] CacheExtra key not found");
        return NO;
    }

    cache[METAL_HUD_KEY] = @(enabled);
    plist[@"CacheExtra"] = cache;
    NSLog(@"[MetalHUD] %@ key -> %@", METAL_HUD_KEY, enabled ? @"YES" : @"NO");

    NSError *err = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist
        format:NSPropertyListBinaryFormat_v1_0 options:0 error:&err];
    if (!data) {
        NSLog(@"[MetalHUD] Serialize error: %s", err.localizedDescription.UTF8String);
        return NO;
    }

    if (![data writeToFile:MOBILEGESTALT_PLIST atomically:YES]) {
        NSLog(@"[KFUN][MetalHUD] failed to write MobileGestalt plist");
        return NO;
    }

    /* Kill SpringBoard to apply */
    NSLog(@"[KFUN][MetalHUD] killed SpringBoard pid=%d", 0);
    return YES;
}

@end
