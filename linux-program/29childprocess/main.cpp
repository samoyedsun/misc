#include "../common.h"

int main(int argc, char* argv[])
{
    signal(SIGCHLD, SIG_IGN);

    pid_t pid = fork();
    if(pid == 0)
    {
        return 0;
    }

    while(1)
    {
        sleep(1);
    }
    return 0;
}


















