/*
 * task_for_pid.c — AovDarksword 1.4
 * Tự động tìm PID game AoV và lấy task port
 * SRD entitlement: com.apple.system-task-ports
 */

#include "task_for_pid.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/sysctl.h>
#if __has_include(<libproc.h>)
#include <libproc.h>
#else
int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
int proc_listpids(uint32_t type, uint32_t typeinfo, void *buffer, int buffersize);
#endif
#include <mach/mach.h>


#pragma mark - Process Enumeration

static int _enum_all_pids(pid_t **out_pids, int *out_count) {
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t len = 0;

    if (sysctl(mib, 4, NULL, &len, NULL, 0) < 0) {
        return -1;
    }

    struct kinfo_proc *procs = (struct kinfo_proc *)malloc(len);
    if (!procs) return -1;

    if (sysctl(mib, 4, procs, &len, NULL, 0) < 0) {
        free(procs);
        return -1;
    }

    int count = (int)(len / sizeof(struct kinfo_proc));
    pid_t *pids = (pid_t *)malloc(count * sizeof(pid_t));
    if (!pids) {
        free(procs);
        return -1;
    }

    for (int i = 0; i < count; i++) {
        pids[i] = procs[i].kp_proc.p_pid;
    }

    free(procs);
    *out_pids = pids;
    *out_count = count;
    return 0;
}

#pragma mark - Bundle ID Matching

static int _path_matches_bundle(const char *path, const char *bundle_id) {
    /* AoV paths look like:
     * /var/containers/Bundle/Application/<UUID>/<AppName>.app/<binary>
     * We check if the path contains the bundle container */
    if (!path || !bundle_id) return 0;

    /* For AoV, we match by known binary names */
    const char *kgvn_names[] = {
        "kgvn", "KGVN", "ArenaOfValor", "aov",
        "LienQuanMobile", "HOK", "hok", NULL
    };

    for (int i = 0; kgvn_names[i]; i++) {
        if (strstr(path, kgvn_names[i])) {
            return 1;
        }
    }

    /* Also check bundle id embedded in container path */
    if (strstr(path, bundle_id)) {
        return 1;
    }

    return 0;
}

#pragma mark - Public API

int find_game_pid(pid_t *out_pid, char *out_name, size_t name_len) {
    pid_t *pids = NULL;
    int count = 0;

    if (_enum_all_pids(&pids, &count) != 0) {
        return -1;
    }

    const char *target_bundles[] = {
        AOV_BUNDLE_KGVN,
        AOV_BUNDLE_HOK,
        NULL
    };

    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];

    for (int i = 0; i < count; i++) {
        pid_t pid = pids[i];
        if (pid <= 0) continue;

        memset(pathbuf, 0, sizeof(pathbuf));
        int ret = proc_pidpath(pid, pathbuf, sizeof(pathbuf));
        if (ret <= 0) continue;

        for (int b = 0; target_bundles[b]; b++) {
            if (_path_matches_bundle(pathbuf, target_bundles[b])) {
                *out_pid = pid;
                if (out_name && name_len > 0) {
                    /* Extract binary name from path */
                    const char *slash = strrchr(pathbuf, '/');
                    const char *name = slash ? (slash + 1) : pathbuf;
                    strncpy(out_name, name, name_len - 1);
                    out_name[name_len - 1] = '\0';
                }
                printf("[%s:%d] process: %s, pid: %u\n",
                       __FUNCTION__, __LINE__, pathbuf, pid);
                free(pids);
                return 0;
            }
        }
    }

    free(pids);
    return -1;
}

int find_process_by_name(const char *name, pid_t *out_pid) {
    pid_t *pids = NULL;
    int count = 0;

    if (_enum_all_pids(&pids, &count) != 0) return -1;

    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    for (int i = 0; i < count; i++) {
        if (pids[i] <= 0) continue;

        memset(pathbuf, 0, sizeof(pathbuf));
        if (proc_pidpath(pids[i], pathbuf, sizeof(pathbuf)) <= 0) continue;

        const char *slash = strrchr(pathbuf, '/');
        const char *pname = slash ? (slash + 1) : pathbuf;

        if (strcmp(pname, name) == 0) {
            *out_pid = pids[i];
            free(pids);
            return 0;
        }
    }

    free(pids);
    return -1;
}

int find_process_by_bundle(const char *bundle_id, pid_t *out_pid) {
    pid_t *pids = NULL;
    int count = 0;

    if (_enum_all_pids(&pids, &count) != 0) return -1;

    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    for (int i = 0; i < count; i++) {
        if (pids[i] <= 0) continue;

        memset(pathbuf, 0, sizeof(pathbuf));
        if (proc_pidpath(pids[i], pathbuf, sizeof(pathbuf)) <= 0) continue;

        if (_path_matches_bundle(pathbuf, bundle_id)) {
            *out_pid = pids[i];
            free(pids);
            return 0;
        }
    }

    free(pids);
    return -1;
}

kern_return_t get_task_port(pid_t pid, mach_port_t *out_task) {
    if (!out_task) return KERN_INVALID_ARGUMENT;

    kern_return_t kr = task_for_pid(mach_task_self(), pid, out_task);
    if (kr != KERN_SUCCESS) {
        printf("[%s:%d] task_for_pid failed for pid %d: %s (kr=%d)\n",
               __FUNCTION__, __LINE__, pid, mach_error_string(kr), kr);
        *out_task = MACH_PORT_NULL;
    } else {
        printf("[%s:%d] Task pid: %d\n", __FUNCTION__, __LINE__, pid);
    }
    return kr;
}

int tfp_attach(tfp_result_t *result) {
    if (!result) return -1;
    memset(result, 0, sizeof(tfp_result_t));

    int ret = find_game_pid(&result->pid, result->name, sizeof(result->name));
    if (ret != 0) {
        return -1;
    }

    /* Get full path */
    proc_pidpath(result->pid, result->path, sizeof(result->path));

    /* Get task port via task_for_pid (requires SRD entitlement) */
    kern_return_t kr = get_task_port(result->pid, &result->task);
    if (kr != KERN_SUCCESS) {
        return -2;
    }

    printf("[%s:%d] Finished successfully\n", __FUNCTION__, __LINE__);
    return 0;
}

void tfp_detach(tfp_result_t *result) {
    if (!result) return;
    if (result->task != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), result->task);
        result->task = MACH_PORT_NULL;
    }
    result->pid = 0;
}

int wait_for_process(const char *name, pid_t *out_pid,
                     int timeout_sec, int interval_ms) {
    int elapsed = 0;
    int interval_us = interval_ms * 1000;
    int attempt = 0;

    while (timeout_sec == 0 || elapsed < timeout_sec) {
        attempt++;
        printf("[~] waiting for AOV process (attempt %d)\n", attempt);

        if (find_process_by_name(name, out_pid) == 0) {
            return 0;
        }

        usleep(interval_us);
        if (timeout_sec > 0) {
            elapsed += interval_ms / 1000;
        }
    }

    printf("[!] Timeout: %s did not restart\n", name);
    return -1;
}
