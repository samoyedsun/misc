#include "../common.h"

int main()
{
    pid_t pid = fork();
    if(pid == 0) // 子进程不退出
    {
        while(1)
        {
            sleep(1);
        }
    }
    return 0;
}
