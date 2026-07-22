/*
 * KFHUDESPView.m — AovDarksword 1.4
 * ESP rendering: boxes, HP bars, distance, names, minimap dots
 */

#import "KFHUDESPView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <mach/mach_time.h>

/* Colors */
#define COLOR_ENEMY   [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:0.9]
#define COLOR_ALLY    [UIColor colorWithRed:0.3 green:0.8 blue:1.0 alpha:0.9]
#define COLOR_MONSTER [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:0.8]
#define COLOR_HP_BG   [UIColor colorWithWhite:0.0 alpha:0.5]
#define COLOR_HP_LOW  [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0]
#define COLOR_HP_MID  [UIColor colorWithRed:1.0 green:0.7 blue:0.0 alpha:1.0]
#define COLOR_HP_FULL [UIColor colorWithRed:0.2 green:1.0 blue:0.3 alpha:1.0]

@implementation KFHUDESPView {
    NSUserDefaults *_defaults;
    uint64_t _lastFrameTime;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        _defaults = [NSUserDefaults standardUserDefaults];
        [self _loadSettings];

        NSLog(@"[ESP] pool init: %d slots, %lu total layers",
              KF_MAX_HEROES, (unsigned long)(KF_MAX_HEROES + KF_MAX_MONSTERS));
    }
    return self;
}

- (void)_loadSettings {
    _showBox         = [_defaults boolForKey:@"kf_showBox"];
    _showLine        = [_defaults boolForKey:@"kf_showLine"];
    _showHPBar       = [_defaults boolForKey:@"kf_showHPBar"];
    _showName        = [_defaults boolForKey:@"kf_showName"];
    _showDist        = [_defaults boolForKey:@"kf_showDist"];
    _showIcon        = [_defaults boolForKey:@"kf_showIcon"];
    _showMonster     = [_defaults boolForKey:@"kf_showMonster"];
    _showMonsterHP   = [_defaults boolForKey:@"kf_showMonsterHP"];
    _showMonsterName = [_defaults boolForKey:@"kf_showMonsterName"];
    _eliteOnly       = [_defaults boolForKey:@"kf_eliteOnly"];
}

#pragma mark - Rendering

- (void)refreshESPView {
    [self _loadSettings];
    [self setNeedsDisplay];
}

- (void)renderESPFrame {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_espDataReady) return;

    uint64_t frameStart = mach_absolute_time();
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    NSLog(@"[KFUN][ESPU] entry localESP=%p hasVP=%d heroes=%d",
          self, 1, _heroCount);

    /* Draw heroes */
    for (int i = 0; i < _heroCount && i < KF_MAX_HEROES; i++) {
        KFHeroSlot *h = &_heroes[i];
        if (h->hp <= 0) continue;

        CGPoint screenPos = CGPointMake(h->hx, h->hy);
        BOOL isEnemy = (h->camp != 1); /* Assume local is camp 1 */
        UIColor *color = isEnemy ? COLOR_ENEMY : COLOR_ALLY;

        /* ESP Box */
        if (_showBox) {
            [self _drawBoxAtPoint:screenPos color:color ctx:ctx];
        }

        /* Line from bottom center */
        if (_showLine && isEnemy) {
            [self _drawLineToPoint:screenPos color:color ctx:ctx];
        }

        /* HP Bar */
        if (_showHPBar) {
            float hpPct = (h->hpMax > 0) ? (h->hp / h->hpMax) : 0;
            [self _drawHPBarAtPoint:screenPos percent:hpPct ctx:ctx];
        }

        /* Name */
        if (_showName) {
            NSString *name = [NSString stringWithUTF8String:h->name];
            [self _drawText:name atPoint:CGPointMake(screenPos.x, screenPos.y - 30)
                      color:color fontSize:9.0];
        }

        /* Distance */
        if (_showDist) {
            float dist = sqrtf(h->x * h->x + h->z * h->z);
            NSString *distStr = [NSString stringWithFormat:@"%.0fm", dist];
            [self _drawText:distStr atPoint:CGPointMake(screenPos.x, screenPos.y + 25)
                      color:[UIColor whiteColor] fontSize:8.0];
        }

        /* Level */
        NSString *lvlStr = [NSString stringWithFormat:@"Lv%d", h->level];
        [self _drawText:lvlStr atPoint:CGPointMake(screenPos.x + 20, screenPos.y - 15)
                  color:[UIColor yellowColor] fontSize:8.0];
    }

    /* Draw monsters */
    if (_showMonster) {
        NSLog(@"[KFUN][MON] render mCount=%d", _monsterCount);
        for (int i = 0; i < _monsterCount && i < KF_MAX_MONSTERS; i++) {
            KFHeroSlot *m = &_monsters[i];
            if (m->hp <= 0) continue;

            CGPoint screenPos = CGPointMake(m->hx, m->hy);

            if (_showMonsterHP) {
                float hpPct = (m->hpMax > 0) ? (m->hp / m->hpMax) : 0;
                [self _drawHPBarAtPoint:screenPos percent:hpPct ctx:ctx];
            }
            if (_showMonsterName) {
                NSString *name = [NSString stringWithUTF8String:m->name];
                [self _drawText:name atPoint:CGPointMake(screenPos.x, screenPos.y - 20)
                          color:COLOR_MONSTER fontSize:8.0];
            }
        }
    }

    /* Timing */
    uint64_t frameEnd = mach_absolute_time();
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    double ms = (double)(frameEnd - frameStart) * info.numer / info.denom / 1e6;
    NSLog(@"[KFUN][TIMING] frame=%.1fms heroes=%d monsters=%d slots=%d",
          ms, _heroCount, _monsterCount, _heroCount + _monsterCount);
}

#pragma mark - Drawing Helpers

- (void)_drawBoxAtPoint:(CGPoint)pt color:(UIColor *)color ctx:(CGContextRef)ctx {
    CGFloat boxW = 30, boxH = 50;
    CGRect boxRect = CGRectMake(pt.x - boxW/2, pt.y - boxH/2, boxW, boxH);

    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    CGContextStrokeRect(ctx, boxRect);
}

- (void)_drawLineToPoint:(CGPoint)pt color:(UIColor *)color ctx:(CGContextRef)ctx {
    CGFloat screenW = self.bounds.size.width;
    CGFloat screenH = self.bounds.size.height;
    CGPoint bottom = CGPointMake(screenW / 2, screenH);

    CGContextSetStrokeColorWithColor(ctx, [color colorWithAlphaComponent:0.4].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextMoveToPoint(ctx, bottom.x, bottom.y);
    CGContextAddLineToPoint(ctx, pt.x, pt.y);
    CGContextStrokePath(ctx);
}

- (void)_drawHPBarAtPoint:(CGPoint)pt percent:(float)pct ctx:(CGContextRef)ctx {
    CGFloat barW = 36, barH = 4;
    CGFloat barX = pt.x - barW / 2;
    CGFloat barY = pt.y - 35;

    /* Background */
    CGContextSetFillColorWithColor(ctx, COLOR_HP_BG.CGColor);
    CGContextFillRect(ctx, CGRectMake(barX, barY, barW, barH));

    /* Fill */
    UIColor *fillColor = (pct > 0.6) ? COLOR_HP_FULL :
                          (pct > 0.3) ? COLOR_HP_MID : COLOR_HP_LOW;
    CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
    CGContextFillRect(ctx, CGRectMake(barX, barY, barW * pct, barH));
}

- (void)_drawText:(NSString *)text atPoint:(CGPoint)pt
            color:(UIColor *)color fontSize:(CGFloat)fontSize {
    if (!text || text.length == 0) return;

    NSDictionary *attrs = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
        NSForegroundColorAttributeName: color,
    };

    CGSize textSize = [text sizeWithAttributes:attrs];
    CGPoint drawPt = CGPointMake(pt.x - textSize.width / 2, pt.y);
    [text drawAtPoint:drawPt withAttributes:attrs];
}

@end
