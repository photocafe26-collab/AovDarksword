/* KFHUDViewController.m */
#import <UIKit/UIKit.h>
@interface KFHUDViewController : UIViewController @end
@implementation KFHUDViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}
- (BOOL)prefersStatusBarHidden { return YES; }
@end
