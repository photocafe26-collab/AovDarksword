/* VideoSanh.h */ #import <UIKit/UIKit.h>
@interface VideoSanh : NSObject
- (void)pickVideoWithCompletion:(void(^)(BOOL))completion fromVC:(UIViewController *)vc;
- (void)restoreVideoWithCompletion:(void(^)(BOOL))completion;
@end
