/*
 * game_state.h — AovDarksword 1.4
 * Game state tracking: actors, camera, minimap, battle detection
 */

#ifndef GAME_STATE_H
#define GAME_STATE_H

#include "aov_offsets.h"
#include <mach/mach.h>

/* Initialize game state tracking */
int  game_state_init(mach_port_t task);

/* Update game state (call each tick) */
int  game_state_update(mach_port_t task, int tick);

/* Reset tracking (when game process dies) */
void game_state_reset(void);

/* Read hero actors into buffer */
int  game_read_heroes(mach_port_t task, KFHeroSlot *out, int maxSlots, int *count);

/* Read monster actors into buffer */
int  game_read_monsters(mach_port_t task, KFHeroSlot *out, int maxSlots, int *count);

/* Camera operations */
int  game_get_camera_fov(mach_port_t task, float *outFOV);
int  game_set_camera_fov(mach_port_t task, float fov);
int  game_restore_camera(mach_port_t task);

/* Minimap data */
int  game_get_minimap_info(mach_port_t task,
                           float *posX, float *posY,
                           float *sizeW, float *sizeH);

/* Local player camp detection */
int  game_detect_local_camp(mach_port_t task);

#endif /* GAME_STATE_H */
