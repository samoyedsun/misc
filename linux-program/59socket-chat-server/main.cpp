#include "../common.h"

int main(int argc, char* argv[])
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(9988);
    addr.sin_addr.s_addr = 0;

    int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 0;
    }

    ret = listen(fd, 5);

//    struct sockaddr_in clientaddr;
//    socklen_t len = sizeof(clientaddr);
//    int fd_connect = accept(fd, (struct sockaddr*)&clientaddr, &len);
    int fd_connect = accept(fd, NULL, NULL);

    pid_t pid = fork();

    // 子进程读取网络数据
    if(pid == 0)
    {
        close(fd);
        while(1)
        {
            char buf[1024];
            memset(buf, 0, sizeof(buf));
            ret = read(fd_connect, buf, sizeof(buf)-1);

            if(ret == 0) // 对方关闭socket
            {
                break;
            }
            if(ret < 0) // 接收数据失败了
            {
                if(errno == EINTR) // read函数被信号打断
                    continue;
                break;
            }

            printf("对方说：%s", buf);
        }
        close(fd_connect);
        return 0;
    }
    else  // 父进程
    {
        while(1)
        {
            char buf[1024];
            fgets(buf, sizeof(buf), stdin);
            int ret = write(fd_connect, buf, strlen(buf));
            if(ret < 0)
            {
                return 0;
            }
            if(ret != strlen(buf))
            {
                // 先不处理，一会儿再说
            }
        }
        close(fd_connect);
    }
    return 0;
}


















