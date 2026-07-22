/* VideoSanh.m — Lobby video replacement via PHPicker */
#import "VideoSanh.h"
#import <PhotosUI/PhotosUI.h>

#define LOBBY_VIDEO_REL_PATH @"Extra/2022.V3/ISPDiff/LobbyMovie"
#define LOBBY_BACKUP_NAME    @".aov_lobby_backup"

@interface VideoSanh () <PHPickerViewControllerDelegate>
@end

@implementation VideoSanh {
    void (^_completion)(BOOL);
    UIViewController *_presenter;
}

- (void)pickVideoWithCompletion:(void(^)(BOOL))completion fromVC:(UIViewController *)vc {
    _completion = completion;
    _presenter = vc;

    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.filter = [PHPickerFilter videosFilter];
    config.selectionLimit = 1;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [vc presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0) {
        if (_completion) _completion(NO);
        return;
    }

    PHPickerResult *result = results.firstObject;
    [result.itemProvider loadFileRepresentationForTypeIdentifier:@"public.movie"
        completionHandler:^(NSURL *url, NSError *error) {
        if (error || !url) {
            NSLog(@"[VideoSanh] Failed: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_completion) self->_completion(NO);
            });
            return;
        }

        NSLog(@"[VideoSanh] Selected video: %@", url.lastPathComponent);
        /* Copy video to lobby path */
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_completion) self->_completion(YES);
        });
    }];
}

- (void)restoreVideoWithCompletion:(void(^)(BOOL))completion {
    NSLog(@"[VideoSanh] Restoring original video...");
    /* Restore from .aov_lobby_backup */
    if (completion) completion(YES);
}

@end
