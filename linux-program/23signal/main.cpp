#include "../common.h"
#include <list>

std::list<int> datas;
void signal_handle(int sig)
{
    if(datas.size() > 0)
        datas.pop_back();
}

int main(int argc, char* argv[])
{
    signal(SIGUSR1, signal_handle);
    
    pid_t pid = fork();
    if(pid == 0)
    {
   //     sleep(1);
        pid_t ppid = getppid();
        while(1)
        {
            int ret = kill(ppid, SIGUSR1);
            if(ret == -1)
                break;
        }
        return 0;
    }

//    sigset_t ss;
//    sigemptyset(&ss);
//    sigaddset(&ss, SIGUSR1);
 //   sigfillset(&ss); // 全部都是1

 //   sigset_t os;

    while(1)
    {
//        usleep(10*1000);
        // 屏蔽SIGUSR1
       // sigprocmask(SIG_BLOCK, &ss, NULL);
//        sigprocmask(SIG_SETMASK, &ss, &os);
        datas.push_back(1);
        // 恢复SIGUSR1
        //sigprocmask(SIG_UNBLOCK, &ss, NULL);
//        sigprocmask(SIG_SETMASK, &os, NULL);
    }
    return 0;
}


















