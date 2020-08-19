#include "../common.h"

int main(int argc, char* argv[])
{
    int pipefd = atoi(argv[1]);
    printf("%d\n", pipefd);

    // 重定向到标准输入
    dup2(pipefd, 0);

    close(pipefd);

    while(1)
    {
        char buf[1024];
        char* p = fgets(buf, sizeof(buf), stdin);
        if(p == NULL)
            break;

        // 处理
        if(*buf == 'a')
        {
            printf("%s", buf);
        }
    }

    printf("39 exiting....");
    return 0;
}


















