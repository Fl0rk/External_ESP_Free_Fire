//
//  HUDHelper.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <cstdint>
#import <spawn.h>
#import <notify.h>
#import "rootless.h"
#import <mach-o/dyld.h>

#import "HUDHelper.h"

extern "C" char **environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

BOOL IsHUDEnabled(void)
{
    NSString *pidString = [NSString stringWithContentsOfFile:ROOT_PATH_NS(PID_PATH)
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];

    if (pidString)
    {
        pid_t pid = (pid_t)[pidString intValue];
        int killed = kill(pid, 0);
        return killed != 0;
    }
    else return false;
}

void SetHUDEnabled(BOOL isEnabled)
{
    notify_post(NOTIFY_DESTROY_HUD);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    static char *executablePath = NULL;
    uint32_t executablePathSize = 0;
    _NSGetExecutablePath(NULL, &executablePathSize);
    executablePath = (char *)calloc(1, executablePathSize);
    _NSGetExecutablePath(executablePath, &executablePathSize);

    if (isEnabled)
    {
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

        pid_t task_pid;
        const char *args[] = { executablePath, "-hud", NULL };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
    }
    else
    {
        NSString *pidString = [NSString stringWithContentsOfFile:ROOT_PATH_NS(PID_PATH)
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];

        if (pidString)
        {
            pid_t pid = (pid_t)[pidString intValue];
            kill(pid, SIGKILL);
            unlink([ROOT_PATH_NS(PID_PATH) UTF8String]);
        }
    }
}
