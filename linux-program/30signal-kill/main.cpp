#include "../common.h"

void sig_handle(int sig)
{
    printf("sig_handle\n");
}

int main(int argc, char* argv[])
{
    signal(SIGINT, sig_handle);

    sleep(1);
    kill(getpid(), SIGINT);

    
    while(1)
    {
        sleep(1);
    }
    return 0;
}


















