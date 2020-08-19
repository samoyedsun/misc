#include "../common.h"

int main(int argc, char* argv[])
{
    int sock_server = socket(AF_INET, SOCK_STREAM, 0);
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(10099);
    addr.sin_addr.s_addr = 0;

    int ret = bind(sock_server, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind error");
        return 0;
    }

    listen(sock_server, 5);


    // epollfd理解成一个集合，但是它也是文件描述符
    int epollfd = epoll_create(1024);

    // 怎么把fd放到epollfd中
    // epoll_ctl将一个文件描述符号放入epollfd中
    struct epoll_event ev;
    ev.events = EPOLLIN | EPOLLET; // 表示关心这个socket的读事件
    ev.data.fd = sock_server; // 在这个结构体中，保存这个文件描述符
    epoll_ctl(epollfd, EPOLL_CTL_ADD, sock_server, &ev);

    while(1)
    {
        // epoll_wait相当于select函数，也是会阻塞，这个函数将集合中，有事件的socket，放入参数指定的数据结构中`
        struct epoll_event outev[8];
        int ret = epoll_wait(epollfd, outev, 8, 1000);
        if(ret < 0)
        {
            if(errno == EINTR)
                continue;
            break;
        }
        if(ret > 0)
        {
            for(int i=0; i<ret; ++i)
            {
                int fd = outev[i].data.fd;
                if(fd == sock_server)
                {
                    int newfd = accept(sock_server, NULL, NULL);
                    // 将新的socket加入到集合
                    ev.events = EPOLLIN;
                    ev.data.fd = newfd;
                    epoll_ctl(epollfd, EPOLL_CTL_ADD, newfd, &ev);
                }
                else
                {
                    char buf[1024];
                    int readlen = read(fd, buf, sizeof(buf));
                    if(readlen <= 0)
                    {
                        printf("some one close fd=%d\n", fd);
                        // close函数自动将fd从epollfd删除，所以直接close即可
                        close(fd);
                    }
                    else
                    {
                        usleep(10*1000);
                        write(fd, "i got it", sizeof("i got it"));
                        //printf("read data is: %s\n", buf);
                    }
                }
            }
        }
    }

    return 0;
}


















