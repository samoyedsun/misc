#include "../common.h"

int main(int argc, char* argv[])
{
    int pipefd[2];

    int ret = pipe(pipefd);
    if(ret < 0)
    {
        perror("pipe");
        return 0;
    }
        
    char buf[1024];

    pid_t pid = fork();
    if(pid == 0)
    {
        close(pipefd[1]);
        close(pipefd[0]);
        // child processs
       // while(1)
      //  {
        //    read(pipefd[0], buf, sizeof(buf));
        //    printf("child process recv buf: %s\n", buf);
      //      sleep(1);
      //  }

    }
    else
    {
        signal(SIGPIPE, SIG_IGN);
        close(pipefd[0]);
        // parent process
        while(1)
        {
            fgets(buf, sizeof(buf), stdin);
            printf("parent process enter %s\n", buf);

            write(pipefd[1], buf, strlen(buf));
        }
    }

    return 0;
}


















