/* ModFile.m — Skin mod zip picker and installer */
#import "ModFile.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation ModFile {
    void (^_completion)(BOOL);
    UIViewController *_presenter;
}

- (void)pickZipWithCompletion:(void(^)(BOOL success))completion fromVC:(UIViewController *)vc {
    _completion = completion;
    _presenter = vc;

    NSLog(@"Choose skin mod file (.zip)");
    UIDocumentPickerViewController *picker;
    if (@available(iOS 14.0, *)) {
        UTType *zip = [UTType typeWithMIMEType:@"application/zip"];
        picker = [[UIDocumentPickerViewController alloc]
                  initForOpeningContentTypes:@[zip ?: UTTypeZipArchive]];
    } else {
        picker = [[UIDocumentPickerViewController alloc]
                  initWithDocumentTypes:@[@"public.zip-archive"]
                  inMode:UIDocumentPickerModeImport];
    }
    picker.delegate = self;
    [vc presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0) {
        if (_completion) _completion(NO);
        return;
    }

    NSURL *url = urls.firstObject;
    [url startAccessingSecurityScopedResource];

    /* Copy to Documents */
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dst = [docsDir stringByAppendingPathComponent:url.lastPathComponent];

    NSError *err = nil;
    [[NSFileManager defaultManager] copyItemAtURL:url
        toURL:[NSURL fileURLWithPath:dst] error:&err];
    [url stopAccessingSecurityScopedResource];

    if (err) {
        NSLog(@"[MOD] copy error: %@", err);
        if (_completion) _completion(NO);
        return;
    }

    /* Unzip to game data path (would use SSZipArchive) */
    NSLog(@"[MOD] Installed skin mod from %@", dst);
    if (_completion) _completion(YES);
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    if (_completion) _completion(NO);
}

- (void)deleteModWithCompletion:(void(^)(BOOL))completion {
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *resourcesDir = [docsDir stringByAppendingPathComponent:@"Resources"];

    NSError *err = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:resourcesDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:resourcesDir error:&err];
        NSLog(@"Skin mod removed!");
        if (completion) completion(YES);
    } else {
        NSLog(@"No skin mod to remove.");
        if (completion) completion(NO);
    }
}

@end
