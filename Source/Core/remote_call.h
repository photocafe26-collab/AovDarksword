/*
 * remote_call.h — AovDarksword 1.4
 */
#ifndef REMOTE_CALL_H
#define REMOTE_CALL_H

#include <stdint.h>
#include <mach/mach.h>

int  init_remote_call(mach_port_t task);
void cleanup_remote_call(void);

int  do_remote_call_stable(const char *symbol, uint64_t *retval, int nargs, ...);
int  do_remote_call_temp(uint64_t funcAddr, uint64_t *retval, int nargs, ...);

int  remote_read(mach_port_t task, uint64_t addr, void *buf, size_t len);
int  remote_write(mach_port_t task, uint64_t addr, const void *buf, size_t len);
uint64_t remote_pac(uint64_t ptr, uint64_t ctx);

uint64_t find_pacia_gadget(mach_port_t task, uint64_t base, uint64_t size);

#endif
