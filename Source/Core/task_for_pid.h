/*
 * task_for_pid.h — AovDarksword 1.4
 * Tự động tìm PID game AoV và lấy task port (SRD entitlement required)
 */

#ifndef TASK_FOR_PID_H
#define TASK_FOR_PID_H

#include <mach/mach.h>
#include <sys/types.h>
#include <stdbool.h>

// Bundle IDs cho AoV
#define AOV_BUNDLE_KGVN   "com.garena.game.kgvn"
#define AOV_BUNDLE_HOK    "com.levelinfinite.hok"

// Kết quả
typedef struct {
    pid_t       pid;
    mach_port_t task;
    char        name[256];
    char        path[1024];
} tfp_result_t;

/*
 * find_game_pid — Quét tất cả process để tìm AoV
 * Sử dụng sysctl(KERN_PROC) + proc_pidpath()
 * Trả về 0 nếu thành công, -1 nếu không tìm thấy
 */
int find_game_pid(pid_t *out_pid, char *out_name, size_t name_len);

/*
 * find_process_by_name — Tìm PID bằng tên process
 */
int find_process_by_name(const char *name, pid_t *out_pid);

/*
 * find_process_by_bundle — Tìm PID bằng bundle identifier
 */
int find_process_by_bundle(const char *bundle_id, pid_t *out_pid);

/*
 * get_task_port — Gọi task_for_pid() để lấy task port
 * Yêu cầu entitlement: com.apple.system-task-ports
 */
kern_return_t get_task_port(pid_t pid, mach_port_t *out_task);

/*
 * tfp_attach — Tìm AoV và attach (combo find + task_for_pid)
 */
int tfp_attach(tfp_result_t *result);

/*
 * tfp_detach — Giải phóng task port
 */
void tfp_detach(tfp_result_t *result);

/*
 * wait_for_process — Đợi process xuất hiện (polling)
 * timeout_sec: thời gian tối đa chờ, 0 = vô hạn
 * interval_ms: khoảng cách giữa các lần quét
 */
int wait_for_process(const char *name, pid_t *out_pid,
                     int timeout_sec, int interval_ms);

#endif /* TASK_FOR_PID_H */
