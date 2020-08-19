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
        execlp("cat", "cat", NULL);
        return 0;
    }
    else
    {
        sleep(1);
        kill(pid, SIGINT);
        while(1)
        {
            sleep(1);
        }
    }
    return 0;
}


















