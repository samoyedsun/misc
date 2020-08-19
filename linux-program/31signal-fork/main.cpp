#include "../common.h"

void sig_handle(int)
{
    printf("sig_handle\n");
}

int main(int argc, char* argv[])
{
    signal(SIGINT, sig_handle);
    pid_t pid = fork();
    if(pid == 0)
    {
        while(1)
        {
            sleep(1);
        }
    }
    else
    {
        kill(pid, SIGINT);
    }
    return 0;
}


















