#import <Foundation/Foundation.h>

@interface ModFile : NSObject
@end

@implementation ModFile

- (void)loadModZip:(NSString *)zipPath {
    NSLog(@"Loading mod zip...");
    // SSZipArchive unzip to game resources
}

@end
