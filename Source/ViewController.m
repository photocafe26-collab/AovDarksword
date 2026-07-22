/*
 * ViewController.m — AovDarksword 1.4
 * Main 3-tab UI: Home / Settings / Docs
 * NO LICENSE KEY — auto-start exploit
 */

#import "ViewController.h"
#import "CoreRuntime.h"
#import "KFCameraSettingsVC.h"
#import "KFHUDESPView.h"
#import "aov_offsets.h"
#import <WebKit/WKWebView.h>
#import <AVKit/AVKit.h>
#import <SafariServices/SafariServices.h>
#import <objc/runtime.h>
#import <sys/utsname.h>

/* Colors */
#define BG_COLOR      [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1]
#define CARD_COLOR    [UIColor colorWithRed:0.15 green:0.15 blue:0.16 alpha:1]
#define ACCENT_BLUE   [UIColor colorWithRed:0.37 green:0.56 blue:1.0 alpha:1]
#define ACCENT_PURPLE [UIColor colorWithRed:0.61 green:0.15 blue:0.90 alpha:1]
#define ACCENT_GOLD   [UIColor colorWithRed:0.98 green:0.78 blue:0.22 alpha:1]
#define TEXT_PRIMARY  [UIColor whiteColor]
#define TEXT_SECONDARY [UIColor colorWithWhite:0.6 alpha:1]

static NSString *const kSpinnerHTML =
    @"<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,"
    @"initial-scale=1'><style>html,body{margin:0;padding:0;background:transparent;"
    @"display:flex;align-items:center;justify-content:center;width:100%;height:100%}"
    @".s{position:relative;width:32px;height:32px}.s div{position:absolute;"
    @"border-radius:50%;animation:r 1.2s cubic-bezier(.5,0,.5,1) infinite}"
    @".r1{width:32px;height:32px;border:2px solid transparent;"
    @"border-top-color:#5e8fff;animation-delay:-.45s}"
    @".r2{width:22px;height:22px;top:5px;left:5px;border:2px solid transparent;"
    @"border-top-color:#9b25e6;animation-delay:-.30s}"
    @".r3{width:12px;height:12px;top:10px;left:10px;border:2px solid transparent;"
    @"border-top-color:#fbc638;animation-delay:-.15s}"
    @"@keyframes r{0%{transform:rotate(0)}100%{transform:rotate(360deg)}}"
    @"</style></head><body><div class='s'><div class='r1'></div>"
    @"<div class='r2'></div><div class='r3'></div></div></body></html>";

@interface ViewController ()

/* Pages */
@property (nonatomic, strong) UIView *homePageView;
@property (nonatomic, strong) UIScrollView *settingsScrollView;
@property (nonatomic, strong) UIView *settingsPageView;
@property (nonatomic, strong) UIView *docsPageView;

/* Tab bar */
@property (nonatomic, strong) UISegmentedControl *tabControl;

/* Status */
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) WKWebView *loadingView;
@property (nonatomic, strong) UIImageView *successIconView;

/* Log */
@property (nonatomic, strong) UITextView *logArea;
@property (nonatomic, strong) UIView *logContainer;

/* Sliders */
@property (nonatomic, strong) UISlider *fovSlider;
@property (nonatomic, strong) UILabel *fovValueLabel;
@property (nonatomic, strong) UISlider *zoomSlider;
@property (nonatomic, strong) UILabel *zoomValueLabel;
@property (nonatomic, strong) UISlider *minimapOffsetXSlider;
@property (nonatomic, strong) UISlider *minimapOffsetYSlider;
@property (nonatomic, strong) UISlider *infoPanelScaleSlider;

/* ESP */
@property (nonatomic, strong) NSMutableArray *espCheckboxButtons;
@property (nonatomic, strong) CADisplayLink *displayLink;

/* Misc */
@property (nonatomic, strong) UIButton *languageButton;

@end

@implementation ViewController {
    NSUserDefaults *_defaults;
    BOOL _isEnglish;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    _defaults = [NSUserDefaults standardUserDefaults];
    _isEnglish = YES;
    _espCheckboxButtons = [NSMutableArray array];

    self.view.backgroundColor = BG_COLOR;

    [self _buildTabBar];
    [self _buildHomePage];
    [self _buildSettingsPage];
    [self _buildDocsPage];
    [self _showPage:0];
    [self loadSpinnerHTML];

    /* Auto-start exploit — NO key required */
    CoreRuntime *rt = [CoreRuntime sharedRuntime];
    rt.delegate = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{
        [self appendLog:@"AovDarksword 1.4 — Starting..."];
        [self appendLog:[self _deviceInfoString]];
        [rt startHackLoop];
    });
}

#pragma mark - Tab Bar

- (void)_buildTabBar {
    _tabControl = [[UISegmentedControl alloc] initWithItems:@[@"Home", @"Settings", @"Docs"]];
    _tabControl.selectedSegmentIndex = 0;
    _tabControl.translatesAutoresizingMaskIntoConstraints = NO;
    _tabControl.selectedSegmentTintColor = ACCENT_BLUE;
    [_tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: TEXT_PRIMARY}
                               forState:UIControlStateSelected];
    [_tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: TEXT_SECONDARY}
                               forState:UIControlStateNormal];
    _tabControl.backgroundColor = CARD_COLOR;
    [_tabControl addTarget:self action:@selector(_tabTapped:)
          forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_tabControl];

    [NSLayoutConstraint activateConstraints:@[
        [_tabControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [_tabControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_tabControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [_tabControl.heightAnchor constraintEqualToConstant:36],
    ]];
}

- (void)_tabTapped:(UISegmentedControl *)seg {
    [self _showPage:seg.selectedSegmentIndex];
}

- (void)_showPage:(NSInteger)idx {
    _homePageView.hidden = (idx != 0);
    _settingsScrollView.hidden = (idx != 1);
    _docsPageView.hidden = (idx != 2);
}

#pragma mark - Home Page

- (void)_buildHomePage {
    _homePageView = [[UIView alloc] init];
    _homePageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_homePageView];

    [NSLayoutConstraint activateConstraints:@[
        [_homePageView.topAnchor constraintEqualToAnchor:_tabControl.bottomAnchor constant:12],
        [_homePageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_homePageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_homePageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    /* Title */
    UILabel *title = [self _label:@"Aov Darksword" size:22 bold:YES];
    title.textColor = ACCENT_GOLD;
    [_homePageView addSubview:title];
    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:_homePageView.topAnchor constant:12],
        [title.centerXAnchor constraintEqualToAnchor:_homePageView.centerXAnchor],
    ]];

    /* Status label */
    _statusLabel = [self _label:@"Initializing..." size:14 bold:NO];
    _statusLabel.textColor = ACCENT_BLUE;
    [_homePageView addSubview:_statusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_statusLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [_statusLabel.centerXAnchor constraintEqualToAnchor:_homePageView.centerXAnchor],
    ]];

    /* Loading spinner */
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    _loadingView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    _loadingView.opaque = NO;
    _loadingView.backgroundColor = [UIColor clearColor];
    _loadingView.scrollView.backgroundColor = [UIColor clearColor];
    [_homePageView addSubview:_loadingView];
    [NSLayoutConstraint activateConstraints:@[
        [_loadingView.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:8],
        [_loadingView.centerXAnchor constraintEqualToAnchor:_homePageView.centerXAnchor],
        [_loadingView.widthAnchor constraintEqualToConstant:44],
        [_loadingView.heightAnchor constraintEqualToConstant:44],
    ]];

    /* Success icon (hidden initially) */
    _successIconView = [[UIImageView alloc] initWithImage:
        [UIImage systemImageNamed:@"checkmark.circle.fill"]];
    _successIconView.translatesAutoresizingMaskIntoConstraints = NO;
    _successIconView.tintColor = [UIColor systemGreenColor];
    _successIconView.hidden = YES;
    [_homePageView addSubview:_successIconView];
    [NSLayoutConstraint activateConstraints:@[
        [_successIconView.centerXAnchor constraintEqualToAnchor:_loadingView.centerXAnchor],
        [_successIconView.centerYAnchor constraintEqualToAnchor:_loadingView.centerYAnchor],
        [_successIconView.widthAnchor constraintEqualToConstant:36],
        [_successIconView.heightAnchor constraintEqualToConstant:36],
    ]];

    /* Log container */
    _logContainer = [[UIView alloc] init];
    _logContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _logContainer.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1];
    _logContainer.layer.cornerRadius = 10;
    _logContainer.clipsToBounds = YES;
    [_homePageView addSubview:_logContainer];

    _logArea = [[UITextView alloc] init];
    _logArea.translatesAutoresizingMaskIntoConstraints = NO;
    _logArea.editable = NO;
    _logArea.backgroundColor = [UIColor clearColor];
    _logArea.textColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:1];
    _logArea.font = [UIFont fontWithName:@"Menlo" size:10];
    _logArea.text = @"";
    [_logContainer addSubview:_logArea];

    [NSLayoutConstraint activateConstraints:@[
        [_logContainer.topAnchor constraintEqualToAnchor:_loadingView.bottomAnchor constant:16],
        [_logContainer.leadingAnchor constraintEqualToAnchor:_homePageView.leadingAnchor constant:16],
        [_logContainer.trailingAnchor constraintEqualToAnchor:_homePageView.trailingAnchor constant:-16],
        [_logContainer.bottomAnchor constraintEqualToAnchor:_homePageView.bottomAnchor constant:-80],
        [_logArea.topAnchor constraintEqualToAnchor:_logContainer.topAnchor constant:8],
        [_logArea.leadingAnchor constraintEqualToAnchor:_logContainer.leadingAnchor constant:8],
        [_logArea.trailingAnchor constraintEqualToAnchor:_logContainer.trailingAnchor constant:-8],
        [_logArea.bottomAnchor constraintEqualToAnchor:_logContainer.bottomAnchor constant:-8],
    ]];

    /* Bottom buttons */
    UIStackView *bottomStack = [[UIStackView alloc] init];
    bottomStack.axis = UILayoutConstraintAxisHorizontal;
    bottomStack.spacing = 12;
    bottomStack.distribution = UIStackViewDistributionFillEqually;
    bottomStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_homePageView addSubview:bottomStack];

    UIButton *telegramBtn = [self _pillButton:@"Telegram" color:ACCENT_BLUE
                                       action:@selector(_openTelegram)];
    UIButton *cameraBtn = [self _pillButton:@"Camera" color:ACCENT_PURPLE
                                     action:@selector(_openCameraSettings)];
    UIButton *closeBtn = [self _pillButton:@"Close" color:[UIColor systemRedColor]
                                    action:@selector(_closeAppTapped)];

    [bottomStack addArrangedSubview:telegramBtn];
    [bottomStack addArrangedSubview:cameraBtn];
    [bottomStack addArrangedSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [bottomStack.bottomAnchor constraintEqualToAnchor:_homePageView.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [bottomStack.leadingAnchor constraintEqualToAnchor:_homePageView.leadingAnchor constant:16],
        [bottomStack.trailingAnchor constraintEqualToAnchor:_homePageView.trailingAnchor constant:-16],
        [bottomStack.heightAnchor constraintEqualToConstant:40],
    ]];
}

#pragma mark - Settings Page

- (void)_buildSettingsPage {
    _settingsScrollView = [[UIScrollView alloc] init];
    _settingsScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _settingsScrollView.hidden = YES;
    [self.view addSubview:_settingsScrollView];

    _settingsPageView = [[UIView alloc] init];
    _settingsPageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsScrollView addSubview:_settingsPageView];

    [NSLayoutConstraint activateConstraints:@[
        [_settingsScrollView.topAnchor constraintEqualToAnchor:_tabControl.bottomAnchor constant:12],
        [_settingsScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_settingsScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_settingsScrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_settingsPageView.topAnchor constraintEqualToAnchor:_settingsScrollView.topAnchor],
        [_settingsPageView.leadingAnchor constraintEqualToAnchor:_settingsScrollView.leadingAnchor],
        [_settingsPageView.trailingAnchor constraintEqualToAnchor:_settingsScrollView.trailingAnchor],
        [_settingsPageView.bottomAnchor constraintEqualToAnchor:_settingsScrollView.bottomAnchor],
        [_settingsPageView.widthAnchor constraintEqualToAnchor:_settingsScrollView.widthAnchor],
    ]];

    CGFloat y = 16;
    NSArray *espToggles = @[
        @[@"Show ESP Box",       @"kf_showBox"],
        @[@"Show Line",          @"kf_showLine"],
        @[@"Show Minimap",       @"kf_showMinimap"],
        @[@"Show Distance",      @"kf_showDist"],
        @[@"Show HP Bar",        @"kf_showHPBar"],
        @[@"Show Name",          @"kf_showName"],
        @[@"Show Info",          @"kf_showInfo"],
        @[@"Show Icon",          @"kf_showIcon"],
        @[@"Stream Mode",        @"kf_streamMode"],
    ];

    /* ESP section header */
    UILabel *espHeader = [self _label:@"ESP SETTINGS" size:13 bold:YES];
    espHeader.textColor = ACCENT_GOLD;
    espHeader.frame = CGRectMake(20, y, 300, 20);
    [_settingsPageView addSubview:espHeader];
    y += 30;

    for (NSArray *item in espToggles) {
        UIView *row = [self _toggleRow:item[0] key:item[1] y:y];
        [_settingsPageView addSubview:row];
        y += 50;
    }

    /* Monster ESP section */
    y += 10;
    UILabel *monHeader = [self _label:@"ESP MONSTER" size:13 bold:YES];
    monHeader.textColor = ACCENT_GOLD;
    monHeader.frame = CGRectMake(20, y, 300, 20);
    [_settingsPageView addSubview:monHeader];
    y += 30;

    NSArray *monToggles = @[
        @[@"Enable Monster ESP", @"kf_showMonster"],
        @[@"Show Monster HP",    @"kf_showMonsterHP"],
        @[@"Elite Only",         @"kf_eliteOnly"],
        @[@"Show Monster Name",  @"kf_showMonsterName"],
    ];

    for (NSArray *item in monToggles) {
        UIView *row = [self _toggleRow:item[0] key:item[1] y:y];
        [_settingsPageView addSubview:row];
        y += 50;
    }

    /* MINIMAP SETTINGS */
    y += 10;
    UILabel *mmHeader = [self _label:@"MINIMAP SETTINGS" size:13 bold:YES];
    mmHeader.textColor = ACCENT_GOLD;
    mmHeader.frame = CGRectMake(20, y, 300, 20);
    [_settingsPageView addSubview:mmHeader];
    y += 30;

    y = [self _addSlider:@"Horizontal X" key:@"kf_mmOffsetX" min:-200 max:200 y:y];
    y = [self _addSlider:@"Vertical Y" key:@"kf_mmOffsetY" min:-200 max:200 y:y];

    /* INFO PANEL SETTINGS */
    y += 10;
    UILabel *ipHeader = [self _label:@"INFO PANEL SETTINGS" size:13 bold:YES];
    ipHeader.textColor = ACCENT_GOLD;
    ipHeader.frame = CGRectMake(20, y, 300, 20);
    [_settingsPageView addSubview:ipHeader];
    y += 30;

    y = [self _addSlider:@"Scale" key:@"kf_ipScale" min:0.5 max:2.0 y:y];
    y = [self _addSlider:@"Offset X" key:@"kf_ipOffsetX" min:-200 max:200 y:y];
    y = [self _addSlider:@"Offset Y" key:@"kf_ipOffsetY" min:-200 max:200 y:y];

    /* MOD section */
    y += 10;
    UILabel *modHeader = [self _label:@"MOD" size:13 bold:YES];
    modHeader.textColor = ACCENT_GOLD;
    modHeader.frame = CGRectMake(20, y, 300, 20);
    [_settingsPageView addSubview:modHeader];
    y += 30;

    UIButton *modSkinBtn = [self _pillButton:@"Skin Mod (.zip)" color:ACCENT_BLUE
                                      action:@selector(_tapModFile)];
    modSkinBtn.frame = CGRectMake(20, y, 160, 36);
    [_settingsPageView addSubview:modSkinBtn];

    UIButton *delModBtn = [self _pillButton:@"Remove Skin Mod" color:[UIColor systemRedColor]
                                     action:@selector(_tapDeleteMod)];
    delModBtn.frame = CGRectMake(190, y, 160, 36);
    [_settingsPageView addSubview:delModBtn];
    y += 50;

    UIButton *videoBtn = [self _pillButton:@"Lobby Mod (video)" color:ACCENT_PURPLE
                                    action:@selector(_tapModSanh)];
    videoBtn.frame = CGRectMake(20, y, 200, 36);
    [_settingsPageView addSubview:videoBtn];
    y += 60;

    /* Set content size */
    [_settingsPageView.heightAnchor constraintEqualToConstant:y].active = YES;
}

#pragma mark - Docs Page

- (void)_buildDocsPage {
    _docsPageView = [[UIView alloc] init];
    _docsPageView.translatesAutoresizingMaskIntoConstraints = NO;
    _docsPageView.hidden = YES;
    [self.view addSubview:_docsPageView];

    [NSLayoutConstraint activateConstraints:@[
        [_docsPageView.topAnchor constraintEqualToAnchor:_tabControl.bottomAnchor constant:12],
        [_docsPageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_docsPageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_docsPageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UITextView *docs = [[UITextView alloc] init];
    docs.translatesAutoresizingMaskIntoConstraints = NO;
    docs.editable = NO;
    docs.backgroundColor = CARD_COLOR;
    docs.textColor = TEXT_PRIMARY;
    docs.font = [UIFont systemFontOfSize:13];
    docs.layer.cornerRadius = 10;
    docs.text =
        @"AovDarksword 1.4\n"
        @"══════════════════\n\n"
        @"ESP Overlay for Arena of Valor\n"
        @"Supports: AoV 17.0→18.7.1, 26.0→26.0.1\n\n"
        @"Features:\n"
        @"• Enemy ESP (Box, Line, HP Bar, Name, Distance)\n"
        @"• Monster ESP (Elite, HP, Name)\n"
        @"• Minimap with position tracking\n"
        @"• Camera FOV & Zoom control\n"
        @"• Stream Mode (anti-recording)\n"
        @"• Skin Mod (via .zip)\n"
        @"• Lobby Video replacement\n"
        @"• Metal HUD performance overlay\n"
        @"• SpringBoard tweaks (StatusBar, 5-icon dock)\n\n"
        @"Telegram: @Anhvu99er\n"
        @"Device: SRD (Security Research Device)\n"
        @"Entitlements: task_for_pid, no-sandbox\n";
    [_docsPageView addSubview:docs];

    [NSLayoutConstraint activateConstraints:@[
        [docs.topAnchor constraintEqualToAnchor:_docsPageView.topAnchor constant:16],
        [docs.leadingAnchor constraintEqualToAnchor:_docsPageView.leadingAnchor constant:16],
        [docs.trailingAnchor constraintEqualToAnchor:_docsPageView.trailingAnchor constant:-16],
        [docs.bottomAnchor constraintEqualToAnchor:_docsPageView.bottomAnchor constant:-16],
    ]];
}

#pragma mark - UI Builders

- (UILabel *)_label:(NSString *)text size:(CGFloat)sz bold:(BOOL)bold {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = text;
    lbl.textColor = TEXT_PRIMARY;
    lbl.font = bold ? [UIFont boldSystemFontOfSize:sz] : [UIFont systemFontOfSize:sz];
    return lbl;
}

- (UIButton *)_pillButton:(NSString *)title color:(UIColor *)color action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 18;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIView *)_toggleRow:(NSString *)title key:(NSString *)key y:(CGFloat)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(16, y, self.view.bounds.size.width - 32, 44)];
    row.backgroundColor = CARD_COLOR;
    row.layer.cornerRadius = 10;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, 200, 24)];
    lbl.text = title;
    lbl.textColor = TEXT_PRIMARY;
    lbl.font = [UIFont systemFontOfSize:14];
    [row addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(row.bounds.size.width - 67, 7, 51, 31)];
    sw.onTintColor = ACCENT_BLUE;
    sw.on = [_defaults boolForKey:key];
    sw.accessibilityIdentifier = key;
    [sw addTarget:self action:@selector(_espToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];

    [_espCheckboxButtons addObject:sw];
    return row;
}

- (CGFloat)_addSlider:(NSString *)title key:(NSString *)key min:(float)min max:(float)max y:(CGFloat)y {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 200, 20)];
    lbl.text = title;
    lbl.textColor = TEXT_SECONDARY;
    lbl.font = [UIFont systemFontOfSize:12];
    [_settingsPageView addSubview:lbl];

    UILabel *valLbl = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 80, y, 60, 20)];
    valLbl.textColor = TEXT_PRIMARY;
    valLbl.textAlignment = NSTextAlignmentRight;
    valLbl.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    [_settingsPageView addSubview:valLbl];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, y + 22, self.view.bounds.size.width - 40, 30)];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = [_defaults floatForKey:key];
    slider.minimumTrackTintColor = ACCENT_BLUE;
    slider.accessibilityIdentifier = key;
    [slider addTarget:self action:@selector(_sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [_settingsPageView addSubview:slider];

    valLbl.text = [NSString stringWithFormat:@"%.1f", slider.value];
    objc_setAssociatedObject(slider, "valLabel", valLbl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return y + 60;
}

#pragma mark - Actions

- (void)_espToggleChanged:(UISwitch *)sw {
    NSString *key = sw.accessibilityIdentifier;
    [_defaults setBool:sw.isOn forKey:key];
    [_defaults synchronize];
    [self appendLog:[NSString stringWithFormat:@"[ESP] %@ = %@", key, sw.isOn ? @"ON" : @"OFF"]];

    if ([key isEqualToString:@"kf_streamMode"]) {
        [self applyStreamMode:sw.isOn];
    }
}

- (void)_sliderChanged:(UISlider *)slider {
    NSString *key = slider.accessibilityIdentifier;
    [_defaults setFloat:slider.value forKey:key];
    UILabel *valLbl = objc_getAssociatedObject(slider, "valLabel");
    valLbl.text = [NSString stringWithFormat:@"%.1f", slider.value];
}

- (void)_openCameraSettings {
    KFCameraSettingsVC *vc = [[KFCameraSettingsVC alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)_openTelegram {
    NSURL *url = [NSURL URLWithString:@"https://t.me/Anhvu99er"];
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
    [self presentViewController:safari animated:YES completion:nil];
}

- (void)_closeAppTapped {
    NSLog(@"ESP overlay will be cleaned before exit.");
    exit(0);
}

- (void)_tapModFile {
    [self appendLog:@"[MOD] Opening skin mod picker..."];
    /* UIDocumentPicker for .zip files */
    NSArray *types = @[@"public.zip-archive"];
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types
                                                              inMode:UIDocumentPickerModeImport];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)_tapDeleteMod {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Remove Skin Mod?"
        message:@"All files in Documents/Resources will be deleted."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *a) {
        [self appendLog:@"Skin mod removed!"];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)_tapModSanh {
    [self appendLog:@"[MOD] Opening video picker..."];
}

- (void)_toggleLanguage {
    _isEnglish = !_isEnglish;
    [_languageButton setTitle:(_isEnglish ? @"EN" : @"VN") forState:UIControlStateNormal];
}

#pragma mark - Loading / Log

- (void)loadSpinnerHTML {
    [_loadingView loadHTMLString:kSpinnerHTML baseURL:nil];
}

- (void)appendLog:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss";
        NSString *ts = [fmt stringFromDate:[NSDate date]];
        NSString *line = [NSString stringWithFormat:@"[%@] %@\n", ts, msg];

        self->_logArea.text = [self->_logArea.text stringByAppendingString:line];

        /* Auto-scroll */
        if (self->_logArea.text.length > 0) {
            NSRange range = NSMakeRange(self->_logArea.text.length - 1, 1);
            [self->_logArea scrollRangeToVisible:range];
        }
    });
}

- (void)applyStreamMode:(BOOL)enabled {
    NSLog(@"[STREAM] setupLocalWindow: wrapping ESP in SecureESPField (streamMode=%@)",
          enabled ? @"ON" : @"OFF");
}

- (NSString *)_deviceInfoString {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *ios = [[UIDevice currentDevice] systemVersion];
    return [NSString stringWithFormat:@"Device: %@ / iOS %@", model, ios];
}

#pragma mark - CoreRuntimeDelegate

- (void)coreRuntime:(id)runtime didUpdateStatus:(NSString *)status {
    _statusLabel.text = status;
    [self appendLog:status];

    if ([status containsString:@"ESP Active"]) {
        _loadingView.hidden = YES;
        _successIconView.hidden = NO;
    }
}

- (void)coreRuntime:(id)runtime didFindGame:(NSString *)name pid:(pid_t)pid {
    [self appendLog:[NSString stringWithFormat:@"[+] Game: %@ pid=%d", name, pid]];
}

- (void)coreRuntime:(id)runtime didFailWithError:(NSString *)error {
    _statusLabel.text = error;
    _statusLabel.textColor = [UIColor systemRedColor];
    [self appendLog:[NSString stringWithFormat:@"[!] %@", error]];
}

- (void)coreRuntimeDidStartESP:(id)runtime {
    [self appendLog:@"ESP Active"];
    /* Start display link for ESP rendering */
    _displayLink = [CADisplayLink displayLinkWithTarget:self
                                               selector:@selector(espDisplayTick:)];
    _displayLink.preferredFramesPerSecond = 30;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - ESP Display

- (void)espDisplayTick:(CADisplayLink *)link {
    /* Update ESP overlay each frame */
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
