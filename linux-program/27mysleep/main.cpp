#include "../common.h"

void sig_handle(int v)
{
    /*  ctrl + c */
    if(v == SIGINT)
    {
        printf("recv ....\n");
    }
}

void mysleep(int seconds)
{
    signal(SIGALRM, sig_handle); 

    int ret = seconds;

    while(ret > 0)
    {
        alarm(ret);
        pause();

        ret = alarm(0);
    }
}

int main(int argc, char* argv[])
{
    signal(SIGINT, sig_handle); 
    time_t t1 = time(NULL);
    mysleep(5);
    time_t t2 = time(NULL);
    printf("t2-t1=%d\n", (int)(t2-t1));
    return 0;
}


















