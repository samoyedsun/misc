#include "../common.h"

void child_handle(int)
{
    printf("child signal come...\n");
    // 回首子进程的PCB
    int status;
    //pid_t child_pid = wait(&status);
    pid_t child_pid = waitpid(0, &status, WUNTRACED|WCONTINUED);
    if(child_pid < 0)
        return;

    if(WIFEXITED(status))
    {
        printf("child process exit\n");

        int exitcode = WEXITSTATUS(status);
        printf("child process exit with %d\n", exitcode);
    }
    else if(WIFSIGNALED(status))
    {
        printf("child process exit by signal\n");

        int sig = WTERMSIG(status);
        printf("child process exit by signal %d\n", sig);
    }
    else if(WIFSTOPPED(status))
    {
        printf("child process stopped\n");
        int sig = WSTOPSIG(status);
        printf("child process stopped by sig = %d\n", sig);
    }
    else if( WIFCONTINUED(status))
    {
        printf("child process continued\n");
    }
    else
    {
         
    }
}

int main(int argc, char* argv[])
{
    signal(SIGCHLD, child_handle);

    pid_t pid = fork();
    if(pid == 0)
    {
        while(1)
        {
            usleep(100*1000);
       //     printf("child hello world\n");
        }
        return 1;
    }
    sleep(1);
#if 0
    kill(pid, SIGSTOP);

    sleep(5);
    sleep(5);
    kill(pid, SIGCONT);
#endif
    kill(pid, SIGINT);
    while(1)
    {
        sleep(1);
    }

    return 0;
}


















