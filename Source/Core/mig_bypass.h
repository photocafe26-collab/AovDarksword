/*
 * mig_bypass.h — AovDarksword 1.4
 */
#ifndef MIG_BYPASS_H
#define MIG_BYPASS_H

#include <stdint.h>

int  mig_bypass_init(uint64_t kernelSlide);
int  mig_bypass_start(void);
void mig_bypass_stop(void);
void mig_bypass_destroy(void);

#endif
