#include "../common.h"

int main(int argc, char* argv[])
{
    // fork exec 执行 39cmd
    // 将38进程标准输出重定向到pipefd[1]
    int pipefd[2];
    int ret = pipe(pipefd);
    if(ret < 0)
    {
        perror("pipe");
        return 0;
    }

    pid_t pid = fork();
    if(pid > 0)
    {
        close(pipefd[0]);
        // 重定向, 将pipefd[1]拷贝1的位置，这样原有的标准输出被覆盖，printf的内容将输出pipefd[1]
        dup2(pipefd[1], 1);
        close(pipefd[1]);

        FILE* fp = stdin;

        if(argc > 1)
        {
            fp = fopen(argv[1], "r");
        }

        while(1) // cat功能
        {
            char buf[1024];
            char* p = fgets(buf, sizeof(buf), fp);
            if(p == NULL)
                break;

            // 输出到管道
            printf("%s", buf);
            fflush(stdout);
        }

        if(argc > 1)
        {
            fclose(fp);
        }
    }
    else
    {
        char pipefd_arg[32];
        sprintf(pipefd_arg, "%d", pipefd[0]);
        close(pipefd[1]);
        execl("../39pipe-cmd/39pipe-cmd.bin", "../39pipe-cmd/39pipe-cmd.bin", pipefd_arg, NULL);
        printf("error execl..\n");
    }

    return 0;
}


















