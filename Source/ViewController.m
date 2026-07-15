#import "ViewController.h"
#import "KFCameraSettingsVC.h"
#import "CoreRuntime.h"
#import "ModFile.h"
#import "VideoSanh.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Setup UI components: Home, Settings, Docs
    [self setupUI];
    
    // Auto-start exploit as per new design (no license key required)
    [[CoreRuntime sharedRuntime] startHackLoop];
}

- (void)setupUI {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, self.view.bounds.size.width - 40, 40)];
    titleLabel.text = @"AovDarksword 1.4 (Keyless)";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [self.view addSubview:titleLabel];
    
    // Example ESP Checkbox
    UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 120, 50, 31)];
    [espSwitch addTarget:self action:@selector(espSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:espSwitch];
    
    UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 120, 200, 31)];
    espLabel.text = @"Enable ESP";
    [self.view addSubview:espLabel];
    
    // Camera settings button
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    cameraBtn.frame = CGRectMake(20, 180, 200, 40);
    [cameraBtn setTitle:@"Camera Settings" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(openCameraSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
}

- (void)espSwitchChanged:(UISwitch *)sender {
    // Enable or disable ESP in CoreRuntime / HUD
}

- (void)openCameraSettings {
    KFCameraSettingsVC *settingsVC = [[KFCameraSettingsVC alloc] init];
    [self presentViewController:settingsVC animated:YES completion:nil];
}

@end
