/* FiveIconDock.m — 5-icon dock via remote call to SpringBoard */
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface FiveIconDock : NSObject
+ (void)applyWithRemoteCall;
@end

@implementation FiveIconDock

+ (void)applyWithRemoteCall {
    NSLog(@"[5ICON] Starting...");

    Class sbIconCtrl = NSClassFromString(@"SBIconController");
    if (!sbIconCtrl) return;

    id controller = ((id(*)(id, SEL))objc_msgSend)(sbIconCtrl, @selector(sharedInstance));
    if (!controller) return;

    SEL dockSel = NSSelectorFromString(@"dockListView");
    if (![controller respondsToSelector:dockSel]) return;

    id dockView = ((id(*)(id, SEL))objc_msgSend)(controller, dockSel);
    if (!dockView) return;

    /* Set grid size for 5 icons */
    SEL layoutSel = NSSelectorFromString(@"layoutConfiguration");
    if ([dockView respondsToSelector:layoutSel]) {
        id layout = ((id(*)(id, SEL))objc_msgSend)(dockView, layoutSel);
        SEL setColsSel = NSSelectorFromString(@"setNumberOfPortraitColumns:");
        if ([layout respondsToSelector:setColsSel]) {
            ((void(*)(id, SEL, NSInteger))objc_msgSend)(layout, setColsSel, 5);
        }
    }

    /* Force layout update */
    SEL setNeedsLayoutSel = @selector(setNeedsLayout);
    if ([dockView respondsToSelector:setNeedsLayoutSel]) {
        ((void(*)(id, SEL))objc_msgSend)(dockView, setNeedsLayoutSel);
    }

    NSLog(@"[5ICON] done");
}

@end
