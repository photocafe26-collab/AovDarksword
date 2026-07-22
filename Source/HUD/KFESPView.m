/* KFESPView.m — Main process ESP view, 30fps display link */
#import "KFESPView.h"
#import "aov_offsets.h"
#import <sys/mman.h>
#import <fcntl.h>

@implementation KFESPView {
    CADisplayLink *_displayLink;
    KFHeroSlot *_heroShm;
    int _shmFd;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;

        /* Map shared memory for hero data from /tmp/kf_esp_heroes */
        _shmFd = open(KF_SHM_ESP_HEROES, O_RDONLY);
        if (_shmFd >= 0) {
            _heroShm = mmap(NULL, sizeof(KFHeroSlot) * KF_MAX_HEROES,
                            PROT_READ, MAP_SHARED, _shmFd, 0);
        }

        /* Start display link at 30fps */
        _displayLink = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(_tick:)];
        _displayLink.preferredFramesPerSecond = 30;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)_tick:(CADisplayLink *)link {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_heroShm) return;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    /* Read and render hero data from shared memory */
    for (int i = 0; i < KF_MAX_HEROES; i++) {
        KFHeroSlot *h = &_heroShm[i];
        if (h->hp <= 0) break;

        /* Draw ESP box */
        CGRect box = CGRectMake(h->hx - 15, h->hy - 25, 30, 50);
        CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokeRect(ctx, box);
    }
}

- (void)dealloc {
    [_displayLink invalidate];
    if (_heroShm) munmap(_heroShm, sizeof(KFHeroSlot) * KF_MAX_HEROES);
    if (_shmFd >= 0) close(_shmFd);
}

@end
