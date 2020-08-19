#include "../common.h"

void time_out()
{
    printf("hello world\n");  
}

void sig_handle(int sig)
{
    if(sig == SIGUSR1)
    {
        time_out();
    }
}

void start_timer(int ns)
{
    signal(SIGUSR1, sig_handle);

    pid_t pid = fork();
    if(pid == 0)
    {
        usleep(ns);
        kill(getppid(), SIGUSR1);
        exit(0);
    } 
}

int main(int argc, char* argv[])
{
    start_timer(1000*1000);

    while(1)
    {
        sleep(1);
    }
    return 0;
}


















