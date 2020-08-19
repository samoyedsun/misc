#include "../common.h"
#include <list>

std::list<int> newfds;

int main(int argc, char* argv[])
{
    int sock_server = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(10099);
    addr.sin_addr.s_addr = 0;

    int ret = bind(sock_server, (struct sockaddr*)&addr, sizeof(addr));

    listen(sock_server, 5);

    while(1)
    {
        // 三个参数，maxfd, readfds, timeval
        int maxfd;
        fd_set readfds;
        struct timeval tv;

        // timeval一秒
        tv.tv_sec = 1;
        tv.tv_usec = 0;

        // 处理集合，把鼠标键盘文件描述符放入集合中
        maxfd = sock_server;

        FD_ZERO(&readfds);
        FD_SET(sock_server, &readfds);
        for(auto it = newfds.begin(); it != newfds.end(); ++it)
        {
            FD_SET(*it, &readfds);
            if(*it > maxfd) maxfd = *it;
        }

        // 获得最大的文件描述符
        maxfd++;

        // 调用select阻塞等待集合中文件描述符的信号
        int ret = select(maxfd, &readfds, NULL, NULL, &tv);
        if(ret == -1)
        {
            if(errno == EINTR)
                continue;
            break;
        }
        else if(ret > 0)
        {
            if(FD_ISSET(sock_server, &readfds))
            {
                int newfd = accept(sock_server, NULL, NULL);
                if(newfd > 0)
                {
                   newfds.push_back(newfd); 
                }
            }

            // 遍历所有的客户端对应的连接
            for(auto it = newfds.begin(); it != newfds.end(); )
            {
                int fd = *it;
                // 如果该客户端有消息
                if(FD_ISSET(fd, &readfds))
                {
                    char buf[1024];
                    // 尝试读消息
                    ret = read(fd, buf, sizeof(buf));
                    // 发现不是正常的消息
                    if(ret <= 0)
                    {
                        close(fd); 
                        // stl在遍历中删除元素是危险的，用it = newfds.erase(it)可以解决问题
                        it = newfds.erase(it);
                        continue;
                    }
                    printf("read data from client: %s\n", buf);
                }
                // 在删除条件不成立时，写一个it++
                it++;
            }
        }
    }

    return 0;
}


















