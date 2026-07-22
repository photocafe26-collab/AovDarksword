/* DeviceInfo.m — Device model identifier mapping */
#import "DeviceInfo.h"
#import <sys/utsname.h>

@implementation DeviceInfo

static NSDictionary *_models = nil;

+ (void)initialize {
    if (self == [DeviceInfo class]) {
        _models = @{
            /* iPhone */
            @"iPhone10,1": @"iPhone 8",
            @"iPhone10,2": @"iPhone 8 Plus",
            @"iPhone10,3": @"iPhone X",
            @"iPhone10,4": @"iPhone 8",
            @"iPhone10,5": @"iPhone 8 Plus",
            @"iPhone10,6": @"iPhone X",
            @"iPhone11,2": @"iPhone XS",
            @"iPhone11,4": @"iPhone XS Max",
            @"iPhone11,6": @"iPhone XS Max",
            @"iPhone11,8": @"iPhone XR",
            @"iPhone12,1": @"iPhone 11",
            @"iPhone12,3": @"iPhone 11 Pro",
            @"iPhone12,5": @"iPhone 11 Pro Max",
            @"iPhone12,8": @"iPhone SE (2nd)",
            @"iPhone13,1": @"iPhone 12 mini",
            @"iPhone13,2": @"iPhone 12",
            @"iPhone13,3": @"iPhone 12 Pro",
            @"iPhone13,4": @"iPhone 12 Pro Max",
            @"iPhone14,2": @"iPhone 13 Pro",
            @"iPhone14,3": @"iPhone 13 Pro Max",
            @"iPhone14,4": @"iPhone 13 mini",
            @"iPhone14,5": @"iPhone 13",
            @"iPhone14,6": @"iPhone SE (3rd)",
            @"iPhone14,7": @"iPhone 14",
            @"iPhone14,8": @"iPhone 14 Plus",
            @"iPhone15,2": @"iPhone 14 Pro",
            @"iPhone15,3": @"iPhone 14 Pro Max",
            @"iPhone15,4": @"iPhone 15",
            @"iPhone15,5": @"iPhone 15 Plus",
            @"iPhone16,1": @"iPhone 15 Pro",
            @"iPhone16,2": @"iPhone 15 Pro Max",
            @"iPhone17,1": @"iPhone 16 Pro",
            @"iPhone17,2": @"iPhone 16 Pro Max",
            @"iPhone17,3": @"iPhone 16",
            @"iPhone17,4": @"iPhone 16 Plus",
            /* iPad Pro */
            @"iPad8,1":  @"iPad Pro 11\" (1st)",
            @"iPad8,2":  @"iPad Pro 11\" (1st)",
            @"iPad8,3":  @"iPad Pro 11\" (1st)",
            @"iPad8,4":  @"iPad Pro 11\" (1st)",
            @"iPad8,5":  @"iPad Pro 12.9\" (3rd)",
            @"iPad8,9":  @"iPad Pro 11\" (2nd)",
            @"iPad8,11": @"iPad Pro 12.9\" (4th)",
            @"iPad13,4": @"iPad Pro 11\" (3rd)",
            @"iPad13,8": @"iPad Pro 12.9\" (5th)",
            @"iPad14,3": @"iPad Pro 11\" (4th)",
            @"iPad14,5": @"iPad Pro 12.9\" (6th)",
            @"iPad16,3": @"iPad Pro 11\" M4",
            @"iPad16,5": @"iPad Pro 13\" M4",
            /* iPad Air */
            @"iPad13,16": @"iPad Air (5th)",
            @"iPad14,8":  @"iPad Air 11\" M2",
            @"iPad14,9":  @"iPad Air 13\" M2",
            /* iPad mini */
            @"iPad14,1":  @"iPad mini (6th)",
        };
    }
}

+ (NSString *)currentHWModel {
    struct utsname sysinfo;
    uname(&sysinfo);
    return [NSString stringWithCString:sysinfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)currentModelName {
    NSString *hw = [self currentHWModel];
    return _models[hw] ?: hw;
}

@end
