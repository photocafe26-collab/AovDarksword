/*
 * il2cpp_resolver.h — AovDarksword 1.4
 * Unity IL2CPP runtime offset resolution
 */

#ifndef IL2CPP_RESOLVER_H
#define IL2CPP_RESOLVER_H

#include <stdint.h>
#include <stdbool.h>
#include <mach/mach.h>

/* Initialize IL2CPP resolver for a target process */
int il2cpp_init(mach_port_t task, pid_t pid);

/* Find UnityFramework base address in target's vm_map */
int il2cpp_find_unity_framework(mach_port_t task,
                                uint64_t *out_base,
                                uint64_t *out_size);

/* Resolve all AoV field offsets */
int il2cpp_resolve_offsets(mach_port_t task, uint64_t unityBase);

/* Find a specific class field offset */
uint64_t il2cpp_find_class_field(mach_port_t task,
                                  uint64_t unityBase,
                                  const char *assemblyName,
                                  const char *namespaceName,
                                  const char *className,
                                  const char *fieldName);

/* Check if game bundle path contains our target */
bool il2cpp_is_aov_bundle(const char *path);

#endif /* IL2CPP_RESOLVER_H */
