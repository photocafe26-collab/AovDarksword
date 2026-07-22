/*
 * sandbox_patch.h — AovDarksword 1.4
 */
#ifndef SANDBOX_PATCH_H
#define SANDBOX_PATCH_H

#include <stdint.h>

int patch_sandbox_ext(void);
int sandbox_add_extension(const char *extension_class, const char *path);

#endif
