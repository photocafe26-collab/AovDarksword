/*
 * KFHUDESPView.h — AovDarksword 1.4
 * ESP overlay rendering view — draws hero boxes, HP bars, distances, names
 */

#import <UIKit/UIKit.h>
#import "aov_offsets.h"

@interface KFHUDESPView : UIView

@property (nonatomic, assign) BOOL espDataReady;
@property (nonatomic, assign) KFHeroSlot heroes[KF_MAX_HEROES];
@property (nonatomic, assign) int heroCount;
@property (nonatomic, assign) KFHeroSlot monsters[KF_MAX_MONSTERS];
@property (nonatomic, assign) int monsterCount;

/* Settings */
@property (nonatomic, assign) BOOL showBox;
@property (nonatomic, assign) BOOL showLine;
@property (nonatomic, assign) BOOL showHPBar;
@property (nonatomic, assign) BOOL showName;
@property (nonatomic, assign) BOOL showDist;
@property (nonatomic, assign) BOOL showIcon;
@property (nonatomic, assign) BOOL showMonster;
@property (nonatomic, assign) BOOL showMonsterHP;
@property (nonatomic, assign) BOOL showMonsterName;
@property (nonatomic, assign) BOOL eliteOnly;

- (void)refreshESPView;
- (void)renderESPFrame;

@end
