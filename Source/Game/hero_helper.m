/*
 * HeroHelper.m — AovDarksword 1.4
 * Hero name/icon database
 */

#import "HeroHelper.h"

@implementation HeroHelper

static NSDictionary<NSNumber *, NSString *> *_heroNames = nil;

+ (void)initialize {
    if (self == [HeroHelper class]) {
        _heroNames = @{
            @(101) : @"Arthur",
            @(102) : @"Toro",
            @(103) : @"Taara",
            @(104) : @"Krixi",
            @(105) : @"Veera",
            @(106) : @"Gildur",
            @(107) : @"Butterfly",
            @(108) : @"Valhein",
            @(109) : @"Yorn",
            @(110) : @"Violet",
            @(111) : @"Natalya",
            @(112) : @"Thane",
            @(113) : @"Ormarr",
            @(114) : @"Diao Chan",
            @(115) : @"Zephys",
            @(116) : @"Murad",
            @(117) : @"Nakroth",
            @(118) : @"Zill",
            @(119) : @"Raz",
            @(120) : @"Ryoma",
            @(121) : @"Lauriel",
            @(122) : @"Liliana",
            @(123) : @"Arum",
            @(124) : @"Xeniel",
            @(125) : @"Superman",
            @(126) : @"Wonder Woman",
            @(127) : @"Batman",
            @(128) : @"The Joker",
            @(129) : @"Flash",
            @(130) : @"Florentino",
            @(131) : @"Tel'Annas",
            @(132) : @"Lindis",
            @(133) : @"Fennik",
            @(134) : @"Slimz",
            @(135) : @"Wisp",
            @(136) : @"Elsu",
            @(137) : @"Hayate",
            @(138) : @"Capheny",
            @(139) : @"Laville",
            @(140) : @"Thorne",
            @(141) : @"Bolt Baron",
            @(142) : @"Flowborn",
            @(143) : @"Iggy",
            @(144) : @"Ata",
            @(145) : @"Errol",
            @(146) : @"Qi",
            @(147) : @"Allain",
            @(148) : @"Volkath",
            @(149) : @"Paine",
            @(150) : @"Keera",
            @(151) : @"Sinestrea",
            @(152) : @"Bright",
            @(153) : @"Lorion",
            @(154) : @"Aya",
            @(155) : @"Elandorr",
            @(156) : @"Yan",
            @(201) : @"Alice",
            @(202) : @"Lumburr",
            @(203) : @"Chaugnar",
            @(204) : @"Cresht",
            @(205) : @"Zip",
            @(206) : @"Baldum",
            @(207) : @"Y'bneth",
            @(208) : @"Annette",
            @(209) : @"Peura",
            @(210) : @"TeeMee",
            @(211) : @"Sephera",
            @(212) : @"Rouie",
            @(213) : @"Ata",
        };
    }
}

+ (NSString *)nameForHeroID:(int)heroID {
    NSString *name = _heroNames[@(heroID)];
    return name ?: @"Unknown Hero";
}

+ (UIImage *)iconForHeroID:(int)heroID {
    NSString *imageName = [NSString stringWithFormat:@"hero_%d", heroID];
    UIImage *icon = [UIImage imageNamed:imageName];
    if (!icon) {
        /* Fallback: try loading from Documents */
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *iconPath = [docsPath stringByAppendingPathComponent:
            [NSString stringWithFormat:@"icons/%d.png", heroID]];
        icon = [UIImage imageWithContentsOfFile:iconPath];
    }
    return icon;
}

@end
