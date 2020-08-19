#include "../common.h"

int main()
{
    pid_t pid = fork();
    if(pid > 0)
    {
        // 等待子进程退出，如果子进程退出，回收子进程的PCB
        wait(NULL);

        while(1)
        {
            sleep(1);
        }
    }
    return 0;
}
