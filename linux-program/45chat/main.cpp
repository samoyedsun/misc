#include "../common.h"

// ./45chat master
// ./45chat slaver 
int main(int argc, char* argv[])
{
    int piperead, pipewrite;

    if(strcmp(argv[1], "master") == 0)
    {
        printf("master enter\n");
        piperead = open("../1.pipe", O_RDONLY);
        pipewrite = open("../2.pipe", O_WRONLY);
    }
    else if(strcmp(argv[1], "slaver") == 0)
    {
        printf("slaver enter\n");
        pipewrite = open("../1.pipe", O_WRONLY);
        piperead = open("../2.pipe", O_RDONLY);
    }
    else
    {
        printf("usage: %s option\n option is master or slaver\n", argv[0]); 
        return 0;
    }
    printf("open pipe ok\n");

    char buf[2048];

    pid_t pid = fork();
    if(pid == 0)
    {
        while(1)
        {
            int ret = read(piperead, buf, sizeof(buf));
            if(ret == 0)
            {
                break;
            }
            printf("对方说：%s", buf);
        }
        kill(getppid(), SIGKILL);
        return 0;
    }

    while(1)
    {
        fgets(buf, sizeof(buf), stdin);
        write(pipewrite, buf, strlen(buf)+1);
    }

    kill(pid, SIGKILL);
    wait(NULL);

    return 0;
}


















