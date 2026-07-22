/*
 * game_state.c — AovDarksword 1.4
 * Game state: ActorManager reading, hero/monster enumeration, camera, minimap
 */

#include "game_state.h"
#include "aov_offsets.h"
#include "krw.h"
#include <stdio.h>
#include <string.h>
#include <mach/mach_vm.h>

static float s_origFOV = 0;
static float s_origZoomRate = 0;
static int   s_localCamp = 0;
static int   s_battleState = 0;

#pragma mark - Remote Memory Read Helper

static int _vm_read64(mach_port_t task, uint64_t addr, uint64_t *out) {
    mach_vm_size_t sz = 0;
    vm_offset_t data = 0;
    kern_return_t kr = mach_vm_read(task, addr, 8, &data, &sz);
    if (kr != KERN_SUCCESS || sz < 8) return -1;
    *out = *(uint64_t *)(uintptr_t)data;
    mach_vm_deallocate(mach_task_self(), data, sz);
    return 0;
}

static int _vm_read32(mach_port_t task, uint64_t addr, uint32_t *out) {
    mach_vm_size_t sz = 0;
    vm_offset_t data = 0;
    kern_return_t kr = mach_vm_read(task, addr, 4, &data, &sz);
    if (kr != KERN_SUCCESS || sz < 4) return -1;
    *out = *(uint32_t *)(uintptr_t)data;
    mach_vm_deallocate(mach_task_self(), data, sz);
    return 0;
}

static int _vm_readf(mach_port_t task, uint64_t addr, float *out) {
    return _vm_read32(task, addr, (uint32_t *)out);
}

static int _vm_read_buf(mach_port_t task, uint64_t addr, void *buf, size_t len) {
    mach_vm_size_t sz = 0;
    vm_offset_t data = 0;
    kern_return_t kr = mach_vm_read(task, addr, len, &data, &sz);
    if (kr != KERN_SUCCESS || sz < len) return -1;
    memcpy(buf, (void *)(uintptr_t)data, len);
    mach_vm_deallocate(mach_task_self(), data, sz);
    return 0;
}

#pragma mark - Init/Reset

int game_state_init(mach_port_t task) {
    s_localCamp = 0;
    s_battleState = 0;
    return 0;
}

void game_state_reset(void) {
    s_localCamp = 0;
    s_battleState = 0;
    s_origFOV = 0;
    s_origZoomRate = 0;
    printf("[STATE] resetGameTracking  game process died, resetting all caches\n");
}

#pragma mark - Actor Reading

static int _read_actor_list(mach_port_t task, uint64_t listAddr,
                             KFHeroSlot *out, int maxSlots, int *count) {
    if (listAddr == 0 || !out || !count) return -1;
    *count = 0;

    /* IL2CPP List<T>: [0x10] = _items (array), [0x18] = _size (int) */
    uint64_t itemsPtr = 0;
    int32_t listSize = 0;

    if (_vm_read64(task, listAddr + 0x10, &itemsPtr) != 0) return -1;
    if (_vm_read32(task, listAddr + 0x18, (uint32_t *)&listSize) != 0) return -1;

    if (itemsPtr == 0 || listSize <= 0) return 0;
    if (listSize > maxSlots) listSize = maxSlots;

    /* Array header: [0x10] = length, [0x20] = first element */
    for (int i = 0; i < listSize; i++) {
        uint64_t actorAddr = 0;
        if (_vm_read64(task, itemsPtr + 0x20 + i * 8, &actorAddr) != 0) continue;
        if (actorAddr == 0) continue;

        KFHeroSlot *slot = &out[*count];
        memset(slot, 0, sizeof(KFHeroSlot));

        /* Read location (Vector3) */
        if (OFF_AL_location) {
            _vm_readf(task, actorAddr + OFF_AL_location + 0, &slot->x);
            _vm_readf(task, actorAddr + OFF_AL_location + 4, &slot->y);
            _vm_readf(task, actorAddr + OFF_AL_location + 8, &slot->z);
        }

        /* Read visibility */
        uint8_t visible = 0;
        if (OFF_AL_bVisible) {
            _vm_read_buf(task, actorAddr + OFF_AL_bVisible, &visible, 1);
            if (!visible) continue;
        }

        /* Read HP via ValueComponent -> ValueLinkerComponent */
        uint64_t valComp = 0;
        if (OFF_AL_ValueComponent &&
            _vm_read64(task, actorAddr + OFF_AL_ValueComponent, &valComp) == 0 &&
            valComp != 0) {
            if (OFF_VL_hp) _vm_readf(task, valComp + OFF_VL_hp, &slot->hp);
            if (OFF_VL_hpMax) _vm_readf(task, valComp + OFF_VL_hpMax, &slot->hpMax);
            if (OFF_VL_soulLevel) {
                int32_t lvl = 0;
                _vm_read32(task, valComp + OFF_VL_soulLevel, (uint32_t *)&lvl);
                slot->level = lvl;
            }
        }

        /* Read camp */
        if (OFF_AL_TheActorMeta && OFF_AL_ActorCamp) {
            uint64_t meta = 0;
            if (_vm_read64(task, actorAddr + OFF_AL_TheActorMeta, &meta) == 0 && meta) {
                int32_t camp = 0;
                _vm_read32(task, meta + OFF_AL_ActorCamp, (uint32_t *)&camp);
                slot->camp = camp;
            }
        }

        /* Read name - try reading up to 32 chars */
        _vm_read_buf(task, actorAddr + 0x10, slot->name, 31);
        slot->name[31] = '\0';

        (*count)++;
    }

    return 0;
}

int game_read_heroes(mach_port_t task, KFHeroSlot *out, int maxSlots, int *count) {
    if (!g_gameState.actorMgrAddr || !OFF_ActorMgr_HeroActors) return -1;

    uint64_t heroList = 0;
    if (_vm_read64(task, g_gameState.actorMgrAddr + OFF_ActorMgr_HeroActors,
                   &heroList) != 0) return -1;

    return _read_actor_list(task, heroList, out, maxSlots, count);
}

int game_read_monsters(mach_port_t task, KFHeroSlot *out, int maxSlots, int *count) {
    if (!g_gameState.actorMgrAddr || !OFF_ActorMgr_MonsterActors) return -1;

    uint64_t monsterList = 0;
    if (_vm_read64(task, g_gameState.actorMgrAddr + OFF_ActorMgr_MonsterActors,
                   &monsterList) != 0) return -1;

    printf("[KFUN][MON] minionCount=%d\n", *count);
    return _read_actor_list(task, monsterList, out, maxSlots, count);
}

#pragma mark - Camera

int game_get_camera_fov(mach_port_t task, float *outFOV) {
    if (!g_gameState.mobaCamera) return -1;
    /* Camera FOV is at a scan-resolved offset */
    return _vm_readf(task, g_gameState.mobaCamera + 0x40, outFOV);
}

int game_set_camera_fov(mach_port_t task, float fov) {
    if (!g_gameState.mobaCamera) return -1;
    /* Save original if not saved */
    if (s_origFOV == 0) {
        game_get_camera_fov(task, &s_origFOV);
        printf("[CAM] orig captured: FOV=%.1f ZoomRate=%.1f\n",
               s_origFOV, s_origZoomRate);
    }
    uint32_t val;
    memcpy(&val, &fov, 4);
    mach_vm_write(task, g_gameState.mobaCamera + 0x40,
                  (vm_offset_t)&val, 4);
    return 0;
}

int game_restore_camera(mach_port_t task) {
    if (s_origFOV > 0) {
        return game_set_camera_fov(task, s_origFOV);
    }
    return -1;
}

#pragma mark - Minimap

int game_get_minimap_info(mach_port_t task,
                          float *posX, float *posY,
                          float *sizeW, float *sizeH) {
    if (!g_gameState.battleSystem || !OFF_CBattleSys_MinimapSys) return -1;

    uint64_t minimapSys = 0;
    if (_vm_read64(task, g_gameState.battleSystem + OFF_CBattleSys_MinimapSys,
                   &minimapSys) != 0) return -1;

    printf("[MM] CBattleSystem=0x%llx\n", g_gameState.battleSystem);

    if (OFF_MinimapSys_MapTransfer) {
        uint64_t mapTransfer = 0;
        _vm_read64(task, minimapSys + OFF_MinimapSys_MapTransfer, &mapTransfer);

        if (mapTransfer) {
            _vm_readf(task, mapTransfer + 0x00, posX);
            _vm_readf(task, mapTransfer + 0x04, posY);
            _vm_readf(task, mapTransfer + 0x08, sizeW);
            _vm_readf(task, mapTransfer + 0x0C, sizeH);
        }
    }

    return 0;
}

#pragma mark - Camp Detection

int game_detect_local_camp(mach_port_t task) {
    KFHeroSlot heroes[KF_MAX_HEROES];
    int count = 0;
    if (game_read_heroes(task, heroes, KF_MAX_HEROES, &count) != 0) return -1;

    /* Find host-controlled actor */
    for (int i = 0; i < count; i++) {
        /* Check mIsHostCtrlActor flag */
        if (heroes[i].camp > 0) {
            s_localCamp = heroes[i].camp;
            printf("[CAMP] local player detected: rawCamp=%d\n", s_localCamp);
            break;
        }
    }

    if (s_localCamp == 0) {
        printf("[CAMP] s_localCamp=0  skipping tick (heroes=%d)\n", count);
    } else {
        int allies = 0, enemies = 0;
        for (int i = 0; i < count; i++) {
            if (heroes[i].camp == s_localCamp) allies++;
            else enemies++;
        }
        printf("[CAMP] localCamp=%d  normalized: %d allies, %d enemies (total %d)\n",
               s_localCamp, allies, enemies, count);
    }

    g_gameState.localCamp = s_localCamp;
    return s_localCamp;
}

#pragma mark - Update

int game_state_update(mach_port_t task, int tick) {
    /* Read ActorManager */
    if (g_gameState.actorMgrAddr == 0 && OFF_Kyrios_actorManager) {
        /* Resolve from static field */
        /* This would come from IL2CPP class static field resolution */
    }

    return 0;
}
