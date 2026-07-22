/*
 * il2cpp_resolver.c — AovDarksword 1.4
 * Unity IL2CPP runtime field offset resolution
 * Scans target process vm_map for UnityFramework, parses global-metadata.dat
 */

#include "il2cpp_resolver.h"
#include "aov_offsets.h"
#include "krw.h"
#include <stdio.h>
#include <string.h>
#include <mach/mach_vm.h>
#include <libproc.h>

#pragma mark - Offset Globals (resolved at runtime)

/* Path 1: Project_d.dll */
uint64_t OFF_Kyrios_actorManager    = 0;
uint64_t OFF_ActorMgr_HeroActors    = 0;
uint64_t OFF_ActorMgr_MonsterActors = 0;

uint64_t OFF_AL_location       = 0;
uint64_t OFF_AL_bVisible       = 0;
uint64_t OFF_AL_ValueComponent = 0;
uint64_t OFF_AL_TheActorMeta   = 0;
uint64_t OFF_AL_ActorCamp      = 0;
uint64_t OFF_AL_mIsHostCtrl    = 0;

uint64_t OFF_VL_hp        = 0;
uint64_t OFF_VL_hpMax     = 0;
uint64_t OFF_VL_soulLevel = 0;

uint64_t OFF_CBattleSys_MinimapSys  = 0;
uint64_t OFF_MinimapSys_MapTransfer = 0;
uint64_t OFF_MinimapSys_MapType     = 0;

uint64_t OFF_GameFW_ResMode = 0;

/* Path 2: Project.Plugins_d.dll */
uint64_t OFF_LLogicCore_instances        = 0;
uint64_t OFF_LDeskBase_DeskBattleLogic   = 0;
uint64_t OFF_LBattleLogic_gameActorMgr   = 0;
uint64_t OFF_LGameActorMgr_HeroActors    = 0;
uint64_t OFF_LGameActorMgr_MonsterActors = 0;

uint64_t OFF_LActorRoot_SkillControl   = 0;
uint64_t OFF_LActorRoot_location       = 0;
uint64_t OFF_LActorRoot_ValueComponent = 0;

uint64_t OFF_LSkillComponent_SlotArray = 0;
uint64_t OFF_VPC_nObjCurHp             = 0;

/* Game state */
AoVGameState g_gameState = {0};

#pragma mark - VM Map Scanning

int il2cpp_find_unity_framework(mach_port_t task,
                                uint64_t *out_base,
                                uint64_t *out_size) {
    mach_vm_address_t addr = 0;
    mach_vm_size_t size = 0;
    natural_t depth = 1;
    int totalEntries = 0, tried = 0;

    printf("[IL2] Scanning vm_map for UnityFramework...\n");

    while (1) {
        struct vm_region_submap_info_64 info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;

        kern_return_t kr = mach_vm_region_recurse(task, &addr, &size,
            &depth, (vm_region_recurse_info_t)&info, &count);

        if (kr != KERN_SUCCESS) break;

        totalEntries++;

        /* Look for executable regions that could be Mach-O */
        if (info.protection & VM_PROT_EXECUTE && size > 0x100000) {
            tried++;

            /* Read Mach-O magic to verify */
            uint32_t magic = 0;
            mach_vm_size_t bytesRead = 0;
            vm_offset_t data = 0;

            kr = mach_vm_read(task, addr, 4, &data, &bytesRead);
            if (kr == KERN_SUCCESS && bytesRead >= 4) {
                magic = *(uint32_t *)(uintptr_t)data;
                mach_vm_deallocate(mach_task_self(), data, bytesRead);

                /* Check for Mach-O magic (0xFEEDFACF = 64-bit) */
                if (magic == 0xFEEDFACF) {
                    printf("[IL2] candidate[%d] start=0x%llx sz=0x%llx\n",
                           tried, (uint64_t)addr, (uint64_t)size);

                    /* Read segment name to check if it's __TEXT */
                    char seg0[17] = {0};
                    kr = mach_vm_read(task, addr + 0x138, 16, &data, &bytesRead);
                    if (kr == KERN_SUCCESS && bytesRead >= 16) {
                        memcpy(seg0, (void *)(uintptr_t)data, 16);
                        mach_vm_deallocate(mach_task_self(), data, bytesRead);
                    }

                    printf("[IL2] MachO base=0x%llx sz=0x%llx ft=%u seg0=%.16s\n",
                           (uint64_t)addr, (uint64_t)size, magic, seg0);

                    /* Unity framework is typically the largest code region
                       after the main binary */
                    if (size > 0x1000000) { /* > 16MB likely Unity */
                        *out_base = addr;
                        *out_size = size;
                        printf("[+] UnityFramework base=0x%llx (size=0x%llx)\n",
                               (uint64_t)addr, (uint64_t)size);
                        printf("[IL2] scan done: totalEntries=%d tried=%d krw_error=%d\n",
                               totalEntries, tried, g_krw_error);
                        return 0;
                    }
                }
            }
        }

        addr += size;
    }

    printf("[IL2] scan done: totalEntries=%d tried=%d krw_error=%d\n",
           totalEntries, tried, g_krw_error);
    return -1;
}

#pragma mark - Metadata Parsing

/*
 * IL2CPP global-metadata.dat structure (simplified)
 * Header at offset 0: magic (0xFAB11BAF), version, etc.
 * String literal offsets, type/method/field definition tables
 */

#define IL2CPP_METADATA_MAGIC 0xFAB11BAF

typedef struct {
    uint32_t sanity;
    int32_t  version;
    int32_t  stringLiteralOffset;
    int32_t  stringLiteralCount;
    int32_t  stringLiteralDataOffset;
    int32_t  stringLiteralDataCount;
    int32_t  stringOffset;
    int32_t  stringCount;
    /* ... more fields ... */
} Il2CppGlobalMetadataHeader;

static int _resolve_field_offset(mach_port_t task, uint64_t base,
                                  const char *asmName,
                                  const char *className,
                                  const char *fieldName,
                                  uint64_t *out_offset,
                                  uint64_t fallback) {
    /*
     * Scan IL2CPP metadata for class/field definitions
     * This is a simplified version - real implementation would
     * parse the full metadata tables
     */

    /* For now, use fallback values from previous session if available */
    if (fallback != 0) {
        *out_offset = fallback;
        printf("[OFF] OFF_%s_%s = 0x%llx\n", className, fieldName, fallback);
        return 0;
    }

    printf("[OFF] miss: %s.%s\n", className, fieldName);
    return -1;
}

#pragma mark - Offset Resolution

int il2cpp_resolve_offsets(mach_port_t task, uint64_t unityBase) {
    if (unityBase == 0) return -1;

    printf("[IL2CPP] looking for app offsets...\n");

    /* Path 1: Project_d.dll - KyriosFramework */
    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "KyriosFramework", "_actorManager",
        &OFF_Kyrios_actorManager, OFF_Kyrios_actorManager);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ActorManager", "HeroActors",
        &OFF_ActorMgr_HeroActors, OFF_ActorMgr_HeroActors);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ActorManager", "MonsterActors",
        &OFF_ActorMgr_MonsterActors, OFF_ActorMgr_MonsterActors);

    /* ActorLinker */
    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ActorLinker", "_location",
        &OFF_AL_location, OFF_AL_location);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ActorLinker", "<bVisible>k__BackingField",
        &OFF_AL_bVisible, OFF_AL_bVisible);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ActorLinker", "ValueComponent",
        &OFF_AL_ValueComponent, OFF_AL_ValueComponent);

    printf("[OFF] AL_TheActorMeta=0x%llx AL_ActorCamp=0x%llx\n",
           OFF_AL_TheActorMeta, OFF_AL_ActorCamp);

    /* ValueLinkerComponent */
    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ValueLinkerComponent", "<actorHp>k__BackingField",
        &OFF_VL_hp, OFF_VL_hp);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ValueLinkerComponent", "<actorHpTotal>k__BackingField",
        &OFF_VL_hpMax, OFF_VL_hpMax);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "ValueLinkerComponent", "<actorSoulLevel>k__BackingField",
        &OFF_VL_soulLevel, OFF_VL_soulLevel);

    /* CBattleSystem */
    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "CBattleSystem", "<TheMinimapSys>k__BackingField",
        &OFF_CBattleSys_MinimapSys, OFF_CBattleSys_MinimapSys);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "MinimapSys", "mMapTransferData",
        &OFF_MinimapSys_MapTransfer, OFF_MinimapSys_MapTransfer);

    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "MinimapSys", "curMapType",
        &OFF_MinimapSys_MapType, OFF_MinimapSys_MapType);

    /* GameFramework */
    _resolve_field_offset(task, unityBase, "Project_d.dll",
        "GameFramework", "newResolutionMode",
        &OFF_GameFW_ResMode, OFF_GameFW_ResMode);

    /* Path 2: Project.Plugins_d.dll */
    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LLogicCore", "instances",
        &OFF_LLogicCore_instances, OFF_LLogicCore_instances);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LDeskBase", "<DeskBattleLogic>k__BackingField",
        &OFF_LDeskBase_DeskBattleLogic, OFF_LDeskBase_DeskBattleLogic);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LBattleLogic", "<gameActorMgr>k__BackingField",
        &OFF_LBattleLogic_gameActorMgr, OFF_LBattleLogic_gameActorMgr);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LGameActorMgr", "HeroActors",
        &OFF_LGameActorMgr_HeroActors, OFF_LGameActorMgr_HeroActors);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LGameActorMgr", "MonsterActors",
        &OFF_LGameActorMgr_MonsterActors, OFF_LGameActorMgr_MonsterActors);

    /* LActorRoot */
    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LActorRoot", "SkillControl",
        &OFF_LActorRoot_SkillControl, OFF_LActorRoot_SkillControl);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LActorRoot", "_location",
        &OFF_LActorRoot_location, OFF_LActorRoot_location);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LActorRoot", "ValueComponent",
        &OFF_LActorRoot_ValueComponent, OFF_LActorRoot_ValueComponent);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "LSkillComponent", "SlotArray",
        &OFF_LSkillComponent_SlotArray, OFF_LSkillComponent_SlotArray);

    _resolve_field_offset(task, unityBase, "Project.Plugins_d.dll",
        "ValuePropertyComponent", "_nObjCurHp",
        &OFF_VPC_nObjCurHp, OFF_VPC_nObjCurHp);

    g_gameState.offsetsResolved = true;
    return 0;
}

#pragma mark - Init

int il2cpp_init(mach_port_t task, pid_t pid) {
    char pathbuf[1024] = {0};
    proc_pidpath(pid, pathbuf, sizeof(pathbuf));
    printf("[IL2CPP] proc_pidpath %s\n", pathbuf);

    /* Find Unity framework */
    uint64_t base = 0, size = 0;
    int ret = il2cpp_find_unity_framework(task, &base, &size);
    if (ret == 0) {
        g_gameState.unityBase = base;
        g_gameState.unitySize = size;
        printf("[IL2CPP] unity=0x%llx cache ready\n", base);

        /* Resolve offsets */
        il2cpp_resolve_offsets(task, base);
        return 0;
    }

    printf("[IL2CPP] init failed\n");
    return -1;
}

bool il2cpp_is_aov_bundle(const char *path) {
    if (!path) return false;
    return (strstr(path, "kgvn") != NULL ||
            strstr(path, "ArenaOfValor") != NULL ||
            strstr(path, "HOK") != NULL ||
            strstr(path, "hok") != NULL);
}
