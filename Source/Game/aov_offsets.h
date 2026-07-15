#ifndef aov_offsets_h
#define aov_offsets_h

struct HeroData {
    float x, y, z;        // 3D position
    float hx, hy, hz;     // Screen position
    float hp, hpMax;      // HP
    int level;            // Level
    int camp;             // Team (red/blue)
    char name[32];        // Hero name
};

// Offsets
#define OFF_Kyrios_actorManager 0x123456
#define OFF_ActorMgr_HeroActors 0x123456

#endif
