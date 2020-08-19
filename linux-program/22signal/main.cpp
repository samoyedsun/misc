#include "../common.h"

time_t t1;
time_t t2;

void signal_handle(int)
{
    t2 = time(NULL);
    printf("alarm, %d\n", (int)(t2-t1));
//    printf("我就是不退出\n");
}

int main(int argc, char* argv[])
{
//    signal(SIGHUP, SIG_IGN);
//    signal(SIGINT, signal_handle);
    signal(SIGALRM, signal_handle);
    t1 = time(NULL);

    pid_t pid = fork();
    if(pid == 0)
    {
        alarm(3);
        while(1)
        {
            sleep(1);
        }
        return 0;
    }

    return 0;

    int ret = alarm(10);
    printf("%d\n", ret);

    sleep(1);
    ret = alarm(5);

    printf("%d\n", ret);
    while(1)
    {
        sleep(1);
    }
    return 0;
}


















