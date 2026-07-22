/*
 * vm_shmem.h — AovDarksword 1.4
 * Shared memory primitives for kernel R/W via VM object manipulation
 */

#ifndef VM_SHMEM_H
#define VM_SHMEM_H

#include <stdint.h>
#include <stdbool.h>
#include <mach/mach.h>

/* Shared memory descriptor */
typedef struct {
    uint64_t localAddr;     /* Userspace mapped address               */
    uint64_t remoteAddr;    /* Kernel virtual address of the mapping  */
    uint64_t size;          /* Size of the shared region              */
    bool     mapped;        /* Whether the region is currently mapped */
} VMShmem;

/*
 * vm_create_shmem_with_object — Create a shared memory region
 *
 * Allocates local memory, creates a memory entry via
 * mach_make_memory_entry_64, and maps it into the target task.
 *
 * @param task        Target task port (e.g. kernel_task)
 * @param size        Size of the shared region (page-aligned)
 * @param shmem       Output VMShmem descriptor
 * @return            KERN_SUCCESS or mach error code
 */
kern_return_t vm_create_shmem_with_object(mach_port_t task,
                                          mach_vm_size_t size,
                                          VMShmem *shmem);

/*
 * vm_map_remote_page — Map a physical page into the current task
 *
 * Uses vm_get_object to find the kernel VM object for a given
 * kernel virtual address, then maps the corresponding physical
 * page into the caller's address space.
 *
 * @param kaddr       Kernel virtual address to map
 * @param pa          Physical address of the page
 * @param out_local   Output: local userspace mapping address
 * @return            KERN_SUCCESS or mach error code
 */
kern_return_t vm_map_remote_page(uint64_t kaddr,
                                 uint64_t pa,
                                 uint64_t *out_local);

/*
 * vm_get_object — Retrieve the VM object for a kernel address
 *
 * Walks the kernel vm_map entries via vm_map_find_entry to locate
 * the vm_object backing the given kernel virtual address.
 *
 * @param kaddr       Kernel virtual address
 * @param out_object  Output: kernel pointer to the vm_object
 * @return            KERN_SUCCESS or mach error code
 */
kern_return_t vm_get_object(uint64_t kaddr, uint64_t *out_object);

#endif /* VM_SHMEM_H */
