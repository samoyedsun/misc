#include "../common.h"

int main(int argc, char* argv[])
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(9988);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    int ret = connect(fd, (struct sockaddr*)&addr, sizeof(addr));

    pid_t pid = fork();
    if(pid == 0)
    {
        while(1)
        {
            char buf[1024];
            memset(buf, 0, sizeof(buf));
            ret = read(fd, buf, sizeof(buf)-1);
            if(ret == 0)
            {
                break;
            }
            if(ret < 0)
            {
                if(errno  == EINTR)
                {
                    continue;
                }
                break;
            }

            printf("对方说：%s", buf);
        } 
        close(fd);
        return 0;
    }
    else
    {
        while(1)
        {
            char buf[1024];
            fgets(buf, sizeof(buf), stdin);

            int ret = write(fd, buf, strlen(buf));
            if(ret != strlen(buf))
            {
                // 傻眼了
            }
        }
    }

    close(fd);

    return 0;
}


















