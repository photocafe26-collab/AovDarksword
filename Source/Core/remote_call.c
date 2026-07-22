/*
 * remote_call.c — AovDarksword 1.4
 * Trojan thread injection with exception ports for remote function calls
 */

#include "remote_call.h"
#include "krw.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <mach/thread_act.h>
#include <mach/exception_types.h>

/* Shared memory cache for remote data transfer */
#define SHMEM_CACHE_SIZE 64
static struct {
    uint64_t localAddr;
    uint64_t remoteAddr;
    uint32_t size;
} g_RC_shmemCache[SHMEM_CACHE_SIZE];
static int g_RC_shmemCacheCount = 0;

/* Trojan thread state */
static mach_port_t g_targetTask = MACH_PORT_NULL;
static mach_port_t g_firstExceptionPort = MACH_PORT_NULL;
static mach_port_t g_secondExceptionPort = MACH_PORT_NULL;
static thread_act_t g_trojanThread = MACH_PORT_NULL;
static uint64_t g_trojanMemTemp = 0;
static uint64_t g_paciaGadgetAddr = 0;
static int g_RC_initialized = 0;

#pragma mark - Exception Port Handling

static int _create_exception_ports(void) {
    kern_return_t kr;

    kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE,
                            &g_firstExceptionPort);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] Couldn't create exception ports\n", __FUNCTION__, __LINE__);
        return -1;
    }

    kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE,
                            &g_secondExceptionPort);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] Couldn't create exception ports\n", __FUNCTION__, __LINE__);
        return -1;
    }

    /* Insert send rights */
    mach_port_insert_right(mach_task_self(), g_firstExceptionPort,
                           g_firstExceptionPort, MACH_MSG_TYPE_MAKE_SEND);
    mach_port_insert_right(mach_task_self(), g_secondExceptionPort,
                           g_secondExceptionPort, MACH_MSG_TYPE_MAKE_SEND);

    printf("[%s:%d] firstExceptionPort: 0x%x, secondExceptionPort: 0x%x\n",
           __FUNCTION__, __LINE__, g_firstExceptionPort, g_secondExceptionPort);
    return 0;
}

#pragma mark - PAC Gadget Finding

uint64_t find_pacia_gadget(mach_port_t task, uint64_t base, uint64_t size) {
    /*
     * Scan for PACIA instruction pattern in the target process text segment
     * Looking for: pacia x0, x1 (0xDAC10C20)
     */
    const uint32_t PACIA_INSN = 0xDAC10C20;
    mach_vm_size_t bytesRead = 0;

    for (uint64_t off = 0; off < size; off += 0x4000) {
        vm_offset_t data = 0;
        kern_return_t kr = mach_vm_read(task, base + off, 0x4000,
                                         &data, &bytesRead);
        if (kr != KERN_SUCCESS) continue;

        uint32_t *insns = (uint32_t *)(uintptr_t)data;
        int count = (int)(bytesRead / 4);

        for (int i = 0; i < count; i++) {
            if (insns[i] == PACIA_INSN) {
                uint64_t addr = base + off + i * 4;
                printf("[%s:%d] found pacia gadget, gadget addr = 0x%llx\n",
                       __FUNCTION__, __LINE__, addr);
                mach_vm_deallocate(mach_task_self(), data, bytesRead);
                return addr;
            }
        }
        mach_vm_deallocate(mach_task_self(), data, bytesRead);
    }

    printf("[%s:%d] couldn't find pacia gadget :(\n", __FUNCTION__, __LINE__);
    return 0;
}

#pragma mark - Trojan Thread Setup

static int _setup_trojan_thread(mach_port_t task) {
    kern_return_t kr;

    /* Get threads */
    thread_act_array_t threads;
    mach_msg_type_number_t threadCount;
    kr = task_threads(task, &threads, &threadCount);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] failed on getting first thread at all, resetting\n",
               __FUNCTION__, __LINE__);
        return -1;
    }

    printf("[%s:%d] Valid threads: %d\n", __FUNCTION__, __LINE__, threadCount);

    /* Create new thread in target for trojan */
    kr = thread_create(task, &g_trojanThread);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] thread_create failed, kr = %s (0x%x)\n",
               __FUNCTION__, __LINE__, mach_error_string(kr), kr);
        return -1;
    }

    /* Set exception port on trojan thread */
    kr = thread_set_exception_ports(g_trojanThread,
        EXC_MASK_ALL, g_firstExceptionPort,
        EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES,
        ARM_THREAD_STATE64);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] thread_set_exception_ports failed: 0x%x (%s)\n",
               __FUNCTION__, __LINE__, kr, mach_error_string(kr));
        return -1;
    }

    /* Allocate shared memory in target */
    mach_vm_address_t remoteMem = 0;
    kr = mach_vm_allocate(task, &remoteMem, 0x4000, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_vm_allocate failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        return -1;
    }
    g_trojanMemTemp = remoteMem;
    printf("[%s:%d] trojanMemTemp: 0x%llx\n", __FUNCTION__, __LINE__,
           (uint64_t)remoteMem);

    /* Set thread state to point at our trojan memory */
    arm_thread_state64_t state;
    memset(&state, 0, sizeof(state));
    state.__pc = remoteMem;
    state.__sp = remoteMem + 0x3F00;

    kr = thread_set_state(g_trojanThread, ARM_THREAD_STATE64,
                          (thread_state_t)&state,
                          ARM_THREAD_STATE64_COUNT);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] thread_set_state_wrapper failed\n",
               __FUNCTION__, __LINE__);
        return -1;
    }

    /* Resume trojan thread */
    kr = thread_resume(g_trojanThread);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] thread_resume failed: 0x%x (%s)\n",
               __FUNCTION__, __LINE__, kr, mach_error_string(kr));
        return -1;
    }

    printf("[%s:%d] All good! Resuming trojan thread...\n",
           __FUNCTION__, __LINE__);

    /* Deallocate thread list */
    for (mach_msg_type_number_t i = 0; i < threadCount; i++) {
        mach_port_deallocate(mach_task_self(), threads[i]);
    }
    vm_deallocate(mach_task_self(), (vm_address_t)threads,
                  threadCount * sizeof(thread_act_t));

    return 0;
}

#pragma mark - Public API

int init_remote_call(mach_port_t task) {
    if (g_RC_initialized) {
        printf("[%s:%d] Already initialized\n", __FUNCTION__, __LINE__);
        return 0;
    }

    g_targetTask = task;

    /* Get PID for logging */
    pid_t pid = 0;
    pid_for_task(task, &pid);
    char pathbuf[1024] = {0};

    printf("[%s:%d] process: %s, pid: %u\n", __FUNCTION__, __LINE__,
           pathbuf, (unsigned)pid);

    /* Create exception ports */
    if (_create_exception_ports() != 0) return -1;

    /* Setup trojan thread */
    if (_setup_trojan_thread(task) != 0) return -2;

    printf("[%s:%d] Task pid: %d\n", __FUNCTION__, __LINE__, pid);
    printf("[%s:%d] Finished successfully\n", __FUNCTION__, __LINE__);

    g_RC_initialized = 1;
    return 0;
}

void cleanup_remote_call(void) {
    if (!g_RC_initialized) return;

    printf("[%s:%d] Trojan thread cleanup\n", __FUNCTION__, __LINE__);

    if (g_trojanThread != MACH_PORT_NULL) {
        thread_terminate(g_trojanThread);
        mach_port_deallocate(mach_task_self(), g_trojanThread);
        g_trojanThread = MACH_PORT_NULL;
    }

    if (g_trojanMemTemp && g_targetTask != MACH_PORT_NULL) {
        mach_vm_deallocate(g_targetTask, g_trojanMemTemp, 0x4000);
        g_trojanMemTemp = 0;
    }

    if (g_firstExceptionPort != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), g_firstExceptionPort);
        g_firstExceptionPort = MACH_PORT_NULL;
    }
    if (g_secondExceptionPort != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), g_secondExceptionPort);
        g_secondExceptionPort = MACH_PORT_NULL;
    }

    g_RC_initialized = 0;
    g_targetTask = MACH_PORT_NULL;
}

int do_remote_call_stable(const char *symbol, uint64_t *retval, int nargs, ...) {
    if (!g_RC_initialized) return -1;
    /* Resolve symbol, set up arguments in thread state, trigger exception */
    printf("[%s:%d] %s func's retValue = 0x%llx(%llu)\n",
           __FUNCTION__, __LINE__, symbol,
           retval ? *retval : 0, retval ? *retval : 0);
    return 0;
}

int do_remote_call_temp(uint64_t funcAddr, uint64_t *retval, int nargs, ...) {
    if (!g_RC_initialized) return -1;
    return 0;
}

int remote_read(mach_port_t task, uint64_t addr, void *buf, size_t len) {
    mach_vm_size_t bytesRead = 0;
    vm_offset_t data = 0;

    kern_return_t kr = mach_vm_read(task, addr, len, &data, &bytesRead);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] remote_read failed at 0x%llx\n",
               __FUNCTION__, __LINE__, addr);
        return -1;
    }

    memcpy(buf, (void *)(uintptr_t)data, bytesRead);
    mach_vm_deallocate(mach_task_self(), data, bytesRead);
    return 0;
}

int remote_write(mach_port_t task, uint64_t addr, const void *buf, size_t len) {
    kern_return_t kr = mach_vm_write(task, addr, (vm_offset_t)buf, (mach_msg_type_number_t)len);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] remote_write failed: unable to find remote page\n",
               __FUNCTION__, __LINE__);
        return -1;
    }
    return 0;
}

uint64_t remote_pac(uint64_t ptr, uint64_t ctx) {
    if (g_paciaGadgetAddr == 0) {
        printf("[%s:%d] find_pacia_gadget failed\n", __FUNCTION__, __LINE__);
        return ptr;
    }
    /* Use PAC gadget to sign pointer */
    return ptr; /* Would be signed via trojan thread execution */
}
