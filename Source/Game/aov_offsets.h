/*
 * aov_offsets.h — AovDarksword 1.4
 * IL2CPP field offsets + ESP data structures + UserDefaults keys
 * Tất cả offsets được resolve runtime bởi il2cpp_resolver
 */

#ifndef AOV_OFFSETS_H
#define AOV_OFFSETS_H

#include <stdint.h>

#pragma mark - ESP Hero Data Structure

/*
 * Struct layout từ binary type encoding:
 * [32{?="x"f"y"f"z"f"hx"f"hy"f"hz"f"hp"f"hpMax"f"level"i"camp"i"name"[32c]}]
 */
typedef struct __attribute__((packed)) {
    float x, y, z;        /* World position */
    float hx, hy, hz;     /* Screen/head position (projected) */
    float hp, hpMax;      /* Health points */
    int   level;          /* Hero level */
    int   camp;           /* Team: 1=blue, 2=red */
    char  name[32];       /* Hero name (UTF-8) */
} KFHeroSlot;

#define KF_MAX_HEROES   32
#define KF_MAX_MONSTERS 64

#pragma mark - Shared Memory Paths

#define KF_SHM_ESP_SCREEN  "/tmp/kf_esp_screen"
#define KF_SHM_ESP_VP      "/tmp/kf_esp_vp"
#define KF_SHM_ESP_HEROES  "/tmp/kf_esp_heroes"
#define KF_HUD_PID_FILE    "/tmp/kf_hud.pid"
#define KF_HUD_AGENT_PLIST "/tmp/kf_hud_agent.plist"
#define KF_HUD_STDOUT_LOG  "/tmp/kf_hud_stdout.log"
#define KF_HUD_STDERR_LOG  "/tmp/kf_hud_stderr.log"

#pragma mark - Launchd

#define KF_HUD_BUNDLE_ID   "app.kumquat2515.spinach8011.hud"
#define KF_HUD_DISMISS_NOTE "app.kumquat2515.spinach8011.hud.dismiss"
#define KF_HUD_SHOW_NOTE    "app.kumquat2515.spinach8011.hud.show"
#define KF_LAUNCH_AGENTS_DIR "/var/mobile/Library/LaunchAgents"

#pragma mark - UserDefaults Keys

#ifdef __OBJC__
/* Minimap */
#define KF_KEY_MM_OFFSET_X      @"kf_mmOffsetX"
#define KF_KEY_MM_OFFSET_Y      @"kf_mmOffsetY"

/* Info Panel */
#define KF_KEY_IP_SCALE         @"kf_ipScale"
#define KF_KEY_IP_OFFSET_X      @"kf_ipOffsetX"
#define KF_KEY_IP_OFFSET_Y      @"kf_ipOffsetY"

/* ESP Toggles */
#define KF_KEY_SHOW_BOX         @"kf_showBox"
#define KF_KEY_SHOW_LINE        @"kf_showLine"
#define KF_KEY_SHOW_MINIMAP     @"kf_showMinimap"
#define KF_KEY_SHOW_DIST        @"kf_showDist"
#define KF_KEY_SHOW_MONSTER     @"kf_showMonster"
#define KF_KEY_SHOW_HPBAR       @"kf_showHPBar"
#define KF_KEY_SHOW_NAME        @"kf_showName"
#define KF_KEY_SHOW_MONSTER_HP  @"kf_showMonsterHP"
#define KF_KEY_ELITE_ONLY       @"kf_eliteOnly"
#define KF_KEY_SHOW_INFO        @"kf_showInfo"
#define KF_KEY_STREAM_MODE      @"kf_streamMode"
#define KF_KEY_SHOW_ICON        @"kf_showIcon"
#define KF_KEY_SHOW_MONSTER_NAME @"kf_showMonsterName"

/* Camera */
#define KF_KEY_CAM_PRESET_IDX   @"kf_camPresetIdx"
#else
/* Minimap */
#define KF_KEY_MM_OFFSET_X      "kf_mmOffsetX"
#define KF_KEY_MM_OFFSET_Y      "kf_mmOffsetY"

/* Info Panel */
#define KF_KEY_IP_SCALE         "kf_ipScale"
#define KF_KEY_IP_OFFSET_X      "kf_ipOffsetX"
#define KF_KEY_IP_OFFSET_Y      "kf_ipOffsetY"

/* ESP Toggles */
#define KF_KEY_SHOW_BOX         "kf_showBox"
#define KF_KEY_SHOW_LINE        "kf_showLine"
#define KF_KEY_SHOW_MINIMAP     "kf_showMinimap"
#define KF_KEY_SHOW_DIST        "kf_showDist"
#define KF_KEY_SHOW_MONSTER     "kf_showMonster"
#define KF_KEY_SHOW_HPBAR       "kf_showHPBar"
#define KF_KEY_SHOW_NAME        "kf_showName"
#define KF_KEY_SHOW_MONSTER_HP  "kf_showMonsterHP"
#define KF_KEY_ELITE_ONLY       "kf_eliteOnly"
#define KF_KEY_SHOW_INFO        "kf_showInfo"
#define KF_KEY_STREAM_MODE      "kf_streamMode"
#define KF_KEY_SHOW_ICON        "kf_showIcon"
#define KF_KEY_SHOW_MONSTER_NAME "kf_showMonsterName"

/* Camera */
#define KF_KEY_CAM_PRESET_IDX   "kf_camPresetIdx"
#endif


#pragma mark - IL2CPP Offsets (resolved at runtime)

/* Path 1: Project_d.dll - KyriosFramework */
extern uint64_t OFF_Kyrios_actorManager;    /* KyriosFramework._actorManager */
extern uint64_t OFF_ActorMgr_HeroActors;    /* ActorManager.HeroActors */
extern uint64_t OFF_ActorMgr_MonsterActors; /* ActorManager.MonsterActors */

/* ActorLinker fields */
extern uint64_t OFF_AL_location;       /* ActorLinker._location */
extern uint64_t OFF_AL_bVisible;       /* ActorLinker.<bVisible>k__BackingField */
extern uint64_t OFF_AL_ValueComponent; /* ActorLinker.ValueComponent */
extern uint64_t OFF_AL_TheActorMeta;   /* ActorLinker.TheActorMeta */
extern uint64_t OFF_AL_ActorCamp;      /* derived from TheActorMeta */
extern uint64_t OFF_AL_mIsHostCtrl;    /* ActorLinker.mIsHostCtrlActor */

/* ValueLinkerComponent */
extern uint64_t OFF_VL_hp;          /* ValueLinkerComponent.<actorHp>k__BackingField */
extern uint64_t OFF_VL_hpMax;       /* ValueLinkerComponent.<actorHpTotal>k__BackingField */
extern uint64_t OFF_VL_soulLevel;   /* ValueLinkerComponent.<actorSoulLevel>k__BackingField */

/* Battle System */
extern uint64_t OFF_CBattleSys_MinimapSys;   /* CBattleSystem.<TheMinimapSys>k__BackingField */
extern uint64_t OFF_MinimapSys_MapTransfer;  /* MinimapSys.mMapTransferData */
extern uint64_t OFF_MinimapSys_MapType;      /* MinimapSys.curMapType */

/* GameFramework */
extern uint64_t OFF_GameFW_ResMode; /* GameFramework.newResolutionMode */

/* Path 2: Project.Plugins_d.dll - NucleusDrive.Logic */
extern uint64_t OFF_LLogicCore_instances;          /* LLogicCore.instances */
extern uint64_t OFF_LDeskBase_DeskBattleLogic;     /* LDeskBase.<DeskBattleLogic>k__BackingField */
extern uint64_t OFF_LBattleLogic_gameActorMgr;     /* LBattleLogic.<gameActorMgr>k__BackingField */
extern uint64_t OFF_LGameActorMgr_HeroActors;      /* LGameActorMgr.HeroActors */
extern uint64_t OFF_LGameActorMgr_MonsterActors;   /* LGameActorMgr.MonsterActors */

/* LActorRoot */
extern uint64_t OFF_LActorRoot_SkillControl;    /* LActorRoot.SkillControl */
extern uint64_t OFF_LActorRoot_location;        /* LActorRoot._location */
extern uint64_t OFF_LActorRoot_ValueComponent;  /* LActorRoot.ValueComponent */

/* LSkillComponent */
extern uint64_t OFF_LSkillComponent_SlotArray;  /* LSkillComponent.SlotArray */

/* ValuePropertyComponent */
extern uint64_t OFF_VPC_nObjCurHp; /* ValuePropertyComponent._nObjCurHp */

#pragma mark - Game Process Info

typedef struct {
    uint64_t unityBase;        /* UnityFramework base address */
    uint64_t unitySize;        /* UnityFramework size */
    uint64_t actorMgrAddr;     /* ActorManager instance */
    uint64_t cameraSystem;     /* CameraSystem address */
    uint64_t mobaCamera;       /* MobaCamera address */
    uint64_t battleSystem;     /* CBattleSystem address */
    uint64_t gameFramework;    /* GameFramework address */
    int      localCamp;        /* Local player camp (1=blue, 2=red) */
    bool     inBattle;         /* Currently in battle */
    bool     offsetsResolved;  /* IL2CPP offsets resolved */
} AoVGameState;

extern AoVGameState g_gameState;

#pragma mark - Camera Presets

typedef struct {
    float fov;
    float zoomRate;
    float pitch;
    const char *name;
} CameraPreset;

#endif /* AOV_OFFSETS_H */
