/* StatusBarTweak.m — Heart emoji + custom date in status bar */
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface StatusBarTweak : NSObject
+ (void)applyWithRemoteCall;
@end

@implementation StatusBarTweak

+ (void)applyWithRemoteCall {
    NSLog(@"[STATUSBAR] Adding heart beside time...");

    /* This runs via remote_call into SpringBoard process */
    /* UIApplication.sharedApplication -> statusBarStateAggregator
       -> _timeItemDateFormatter, _shortTimeItemDateFormatter */

    /* Set custom format: HH:mm - E d/M/yyyy */
    Class UIApp = NSClassFromString(@"UIApplication");
    if (!UIApp) return;

    id app = ((id(*)(id, SEL))objc_msgSend)(UIApp, @selector(sharedApplication));
    if (!app) return;

    /* Get status bar */
    SEL aggSel = NSSelectorFromString(@"statusBarStateAggregator");
    if (![app respondsToSelector:aggSel]) return;

    id aggregator = ((id(*)(id, SEL))objc_msgSend)(app, aggSel);
    if (!aggregator) return;

    /* Set date formatter */
    SEL fmtSel = NSSelectorFromString(@"_timeItemDateFormatter");
    if ([aggregator respondsToSelector:fmtSel]) {
        NSDateFormatter *fmt = ((id(*)(id, SEL))objc_msgSend)(aggregator, fmtSel);
        if (fmt) {
            fmt.dateFormat = @"❤️ HH:mm - E d/M/yyyy";
        }
    }

    SEL shortFmtSel = NSSelectorFromString(@"_shortTimeItemDateFormatter");
    if ([aggregator respondsToSelector:shortFmtSel]) {
        NSDateFormatter *fmt = ((id(*)(id, SEL))objc_msgSend)(aggregator, shortFmtSel);
        if (fmt) {
            fmt.dateFormat = @"❤️ HH:mm";
        }
    }

    /* Force update */
    SEL updateSel = NSSelectorFromString(@"_updateTimeItems");
    if ([aggregator respondsToSelector:updateSel]) {
        [aggregator performSelectorOnMainThread:updateSel withObject:nil waitUntilDone:NO];
    }
}

@end
