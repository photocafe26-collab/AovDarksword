/* HideLabels.m — Hide SpringBoard icon labels via remote call */
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface HideLabels : NSObject
+ (void)applyWithRemoteCall;
@end

@implementation HideLabels

+ (void)applyWithRemoteCall {
    NSLog(@"[HIDELABEL] Hiding icon labels...");

    /* Run in SpringBoard process via remote_call */
    Class sbIconCtrl = NSClassFromString(@"SBIconController");
    if (!sbIconCtrl) return;

    id controller = ((id(*)(id, SEL))objc_msgSend)(sbIconCtrl, @selector(sharedInstance));
    if (!controller) return;

    /* Get dock list view */
    SEL iconMgrSel = NSSelectorFromString(@"iconManager");
    SEL dockSel = NSSelectorFromString(@"dockListView");
    SEL rootFolderSel = NSSelectorFromString(@"rootFolderController");
    SEL iconListsSel = NSSelectorFromString(@"iconListViews");

    int hiddenCount = 0;

    /* Hide labels on root folder icon lists */
    if ([controller respondsToSelector:rootFolderSel]) {
        id rootFC = ((id(*)(id, SEL))objc_msgSend)(controller, rootFolderSel);
        if (rootFC && [rootFC respondsToSelector:iconListsSel]) {
            NSArray *lists = ((id(*)(id, SEL))objc_msgSend)(rootFC, iconListsSel);
            SEL setLabelSel = NSSelectorFromString(@"setAllowsLabelArea:");
            for (id listView in lists) {
                if ([listView respondsToSelector:setLabelSel]) {
                    ((void(*)(id, SEL, BOOL))objc_msgSend)(listView, setLabelSel, NO);
                    hiddenCount++;
                }
            }
        }
    }

    NSLog(@"[HIDELABEL] Hidden labels on %d icon views", hiddenCount);
}

@end
