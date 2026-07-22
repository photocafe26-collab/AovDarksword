/*
 * grab_kernelcache.h — AovDarksword 1.4
 * Grab kernelcache from disk via vnode v_data swap
 * Initialize XPF (kernel symbol resolution via libxpf)
 */

#ifndef GRAB_KERNELCACHE_H
#define GRAB_KERNELCACHE_H

#import <Foundation/Foundation.h>
#include <stdint.h>

/*
 * grab_kernelcache — Copy the running kernelcache to dstDir
 *
 * Resolves the boot manifest hash, then opens the kernelcache
 * at /System/Library/Caches/com.apple.kernelcaches/kernelcache
 * via vnode v_data swap to bypass sandbox.
 *
 * @param dstDir  Destination directory (e.g. app container tmp)
 * @return        Full path to copied kernelcache, or nil on failure
 */
NSString *grab_kernelcache(NSString *dstDir);

/*
 * init_xpf — Initialize libxpf with the grabbed kernelcache
 *
 * Calls xpf_start_with_kernel_path(), then resolves critical
 * symbols: gVirtBase, gPhysBase, vm_map->pmap offset.
 *
 * @param kcPath      Path to the kernelcache on disk
 * @param kernelSlide KASLR slide value
 * @return            0 on success, -1 on failure
 */
int init_xpf(NSString *kcPath, uint64_t kernelSlide);

/*
 * get_boot_manifest_hash — Resolve the boot manifest hash
 *
 * Tries 3 methods in order:
 *   1. /usr/standalone/firmware
 *   2. /private/preboot/Cryptexes
 *   3. /private/preboot
 *
 * @return  Heap-allocated hash string, or NULL on failure.
 *          Caller must free().
 */
char *get_boot_manifest_hash(void);

#endif /* GRAB_KERNELCACHE_H */
