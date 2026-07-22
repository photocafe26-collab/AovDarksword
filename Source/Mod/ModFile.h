/* ModFile.h */ #import <UIKit/UIKit.h>
@interface ModFile : NSObject <UIDocumentPickerDelegate>
- (void)pickZipWithCompletion:(void(^)(BOOL success))completion fromVC:(UIViewController *)vc;
- (void)deleteModWithCompletion:(void(^)(BOOL success))completion;
@end
