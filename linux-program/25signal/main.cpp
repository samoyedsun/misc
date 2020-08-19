#include "../common.h"

void usr_handle(int)
{
    printf("usr_handle called\n");
}

void rt_handle(int sig)
{
    printf("rt_handle called, sig=%d\n", sig);
}

int main(int argc, char* argv[])
{
    // 父进程注册一些处理函数
    signal(SIGUSR1, usr_handle);
    signal(35, rt_handle);
    signal(34, rt_handle);

    // 设置信号掩码
    sigset_t set;
    sigfillset(&set);
    sigset_t oldset;

    sigprocmask(SIG_SETMASK, &set, &oldset);

    pid_t pid = fork();
    if(pid == 0)
    {
        // 发好几个信号给父进程
        pid_t ppid = getppid();

        kill(ppid, SIGUSR1);
        kill(ppid, SIGUSR1);
        kill(ppid, SIGUSR1);
        kill(ppid, SIGUSR1);

        kill(ppid, 34);
        kill(ppid, 35);
        kill(ppid, 34);
        kill(ppid, 35);
        return 0;
    }

    // 让掩码恢复得慢一些，等子进程发送完信号再说
    sleep(1);

    // 恢复信号的掩码
    sigprocmask(SIG_SETMASK, &oldset, NULL);

    while(1)
    {
        sleep(1);
    }

    return 0;
}


















