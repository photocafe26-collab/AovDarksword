/* KFCameraSettingsVC.m — Camera preset buttons, FOV/zoom sliders */
#import "KFCameraSettingsVC.h"
#import "aov_offsets.h"

#define BG_COLOR   [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1]
#define CARD_COLOR [UIColor colorWithRed:0.15 green:0.15 blue:0.16 alpha:1]
#define ACCENT     [UIColor colorWithRed:0.37 green:0.56 blue:1.0 alpha:1]

static const CameraPreset kPresets[] = {
    { 60.0f,  1.0f, 45.0f, "Default" },
    { 80.0f,  0.8f, 40.0f, "Wide" },
    { 100.0f, 0.6f, 35.0f, "Ultra Wide" },
    { 45.0f,  1.5f, 55.0f, "Close" },
    { 90.0f,  0.5f, 30.0f, "Bird's Eye" },
};
#define PRESET_COUNT (sizeof(kPresets) / sizeof(kPresets[0]))

@implementation KFCameraSettingsVC {
    NSArray<UIButton *> *_presetBtns;
    UISlider *_fovSlider;
    UILabel  *_fovValLbl;
    UISlider *_zoomSlider;
    UILabel  *_zoomValueLabel;
    NSInteger _selectedPreset;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = BG_COLOR;
    _selectedPreset = [[NSUserDefaults standardUserDefaults] integerForKey:@"kf_camPresetIdx"];

    CGFloat y = 60;

    /* Title */
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 300, 30)];
    title.text = @"Camera Settings";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:20];
    [self.view addSubview:title];

    /* Close button */
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(self.view.bounds.size.width - 60, 20, 40, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(_dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];

    /* Preset buttons */
    NSMutableArray *btns = [NSMutableArray array];
    CGFloat btnW = (self.view.bounds.size.width - 40 - (PRESET_COUNT - 1) * 8) / PRESET_COUNT;

    for (int i = 0; i < PRESET_COUNT; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20 + i * (btnW + 8), y, btnW, 36);
        [btn setTitle:[NSString stringWithUTF8String:kPresets[i].name]
             forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.backgroundColor = (i == _selectedPreset) ? ACCENT : CARD_COLOR;
        btn.layer.cornerRadius = 8;
        btn.tag = i;
        [btn addTarget:self action:@selector(presetTapped:)
              forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        [btns addObject:btn];
    }
    _presetBtns = btns;
    y += 50;

    /* FOV Slider */
    UILabel *fovLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 100, 20)];
    fovLbl.text = @"Camera FOV";
    fovLbl.textColor = [UIColor lightGrayColor];
    fovLbl.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:fovLbl];

    _fovValLbl = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 80, y, 60, 20)];
    _fovValLbl.textColor = [UIColor whiteColor];
    _fovValLbl.textAlignment = NSTextAlignmentRight;
    _fovValLbl.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    [self.view addSubview:_fovValLbl];
    y += 22;

    _fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, y, self.view.bounds.size.width - 40, 30)];
    _fovSlider.minimumValue = 30;
    _fovSlider.maximumValue = 120;
    _fovSlider.value = kPresets[_selectedPreset].fov;
    _fovSlider.minimumTrackTintColor = ACCENT;
    [_fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_fovSlider];
    _fovValLbl.text = [NSString stringWithFormat:@"%.0f°", _fovSlider.value];
    y += 50;

    /* Zoom Slider */
    UILabel *zoomLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 100, 20)];
    zoomLbl.text = @"Zoom Rate";
    zoomLbl.textColor = [UIColor lightGrayColor];
    zoomLbl.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:zoomLbl];

    _zoomValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 80, y, 60, 20)];
    _zoomValueLabel.textColor = [UIColor whiteColor];
    _zoomValueLabel.textAlignment = NSTextAlignmentRight;
    _zoomValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    [self.view addSubview:_zoomValueLabel];
    y += 22;

    _zoomSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, y, self.view.bounds.size.width - 40, 30)];
    _zoomSlider.minimumValue = 0.3;
    _zoomSlider.maximumValue = 3.0;
    _zoomSlider.value = kPresets[_selectedPreset].zoomRate;
    _zoomSlider.minimumTrackTintColor = ACCENT;
    [_zoomSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_zoomSlider];
    _zoomValueLabel.text = [NSString stringWithFormat:@"%.1fx", _zoomSlider.value];
    y += 50;

    /* Restore button */
    UIButton *restoreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    restoreBtn.frame = CGRectMake(20, y, self.view.bounds.size.width - 40, 40);
    [restoreBtn setTitle:@"Restore Original Camera" forState:UIControlStateNormal];
    [restoreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    restoreBtn.backgroundColor = [UIColor systemOrangeColor];
    restoreBtn.layer.cornerRadius = 10;
    [restoreBtn addTarget:self action:@selector(_restoreCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:restoreBtn];
}

- (void)presetTapped:(UIButton *)btn {
    _selectedPreset = btn.tag;
    [[NSUserDefaults standardUserDefaults] setInteger:_selectedPreset forKey:@"kf_camPresetIdx"];

    _fovSlider.value = kPresets[_selectedPreset].fov;
    _zoomSlider.value = kPresets[_selectedPreset].zoomRate;
    _fovValLbl.text = [NSString stringWithFormat:@"%.0f°", _fovSlider.value];
    _zoomValueLabel.text = [NSString stringWithFormat:@"%.1fx", _zoomSlider.value];

    [self _updatePresetButtons];
}

- (void)fovChanged:(UISlider *)slider {
    _fovValLbl.text = [NSString stringWithFormat:@"%.0f°", _fovSlider.value];
    _zoomValueLabel.text = [NSString stringWithFormat:@"%.1fx", _zoomSlider.value];
}

- (void)_updatePresetButtons {
    for (int i = 0; i < (int)_presetBtns.count; i++) {
        _presetBtns[i].backgroundColor = (i == _selectedPreset) ? ACCENT : CARD_COLOR;
    }
}

- (void)_restoreCamera {
    NSLog(@"Restore Original Camera");
}

- (void)_dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
