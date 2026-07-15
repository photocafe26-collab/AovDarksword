#import "KFCameraSettingsVC.h"

@interface KFCameraSettingsVC ()

@property (nonatomic, strong) UISlider *fovSlider;
@property (nonatomic, strong) UILabel *fovLabel;

@property (nonatomic, strong) UISlider *zoomSlider;
@property (nonatomic, strong) UILabel *zoomLabel;

@end

@implementation KFCameraSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 200, 30)];
    title.text = @"Camera Settings";
    title.font = [UIFont boldSystemFontOfSize:20];
    [self.view addSubview:title];
    
    // FOV Slider
    self.fovLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 200, 30)];
    self.fovLabel.text = @"FOV: 60";
    [self.view addSubview:self.fovLabel];
    
    self.fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, 30)];
    self.fovSlider.minimumValue = 40;
    self.fovSlider.maximumValue = 120;
    self.fovSlider.value = 60;
    [self.fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.fovSlider];
    
    // Zoom Slider
    self.zoomLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 150, 200, 30)];
    self.zoomLabel.text = @"Zoom Rate: 1.0";
    [self.view addSubview:self.zoomLabel];
    
    self.zoomSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 180, self.view.bounds.size.width - 40, 30)];
    self.zoomSlider.minimumValue = 0.5;
    self.zoomSlider.maximumValue = 3.0;
    self.zoomSlider.value = 1.0;
    [self.zoomSlider addTarget:self action:@selector(zoomChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.zoomSlider];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(20, 250, 100, 40);
    [closeBtn setTitle:@"Close" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
}

- (void)fovChanged:(UISlider *)sender {
    self.fovLabel.text = [NSString stringWithFormat:@"FOV: %.1f", sender.value];
    // update camera FOV in game memory
}

- (void)zoomChanged:(UISlider *)sender {
    self.zoomLabel.text = [NSString stringWithFormat:@"Zoom Rate: %.2f", sender.value];
    // update camera zoom in game memory
}

- (void)closeVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
