#include "../common.h"

void epoll_add(int epfd, int sockfd, int e)
{
    struct epoll_event ev;
    ev.events = e;
    ev.data.fd = sockfd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, sockfd, &ev);
}

void set_nonblock(int fd)
{
    int ret = fcntl(fd, F_GETFL, 0);
    ret |= O_NONBLOCK;
    fcntl(fd, F_SETFL, ret);
}

int main(int argc, char* argv[])
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if(fd < 0)
    {
        perror("socket");
        return 0;
    }

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(10991);
    addr.sin_addr.s_addr = 0;

    int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 0;
    }

    listen(fd, 10);

    int epfd = epoll_create(1024);
    epoll_add(epfd, fd, EPOLLIN | EPOLLET);


    set_nonblock(fd);

    while(1)
    {
        struct epoll_event ev[8];
        ret = epoll_wait(epfd, ev, 8, 5000);
        if(ret > 0)
        {
            for(int i=0; i<ret; ++i)
            {
                if(ev[i].data.fd == fd)
                {
                    // 由于服务器使用的ET触发，所以一旦通知服务器有数据，
                    // 就应该调用accept或者read，一直到清空缓冲区
                    while(1)
                    {
                        // 问题是accept阻塞的
                        int newfd = accept(fd, NULL, NULL);
                        if(newfd == -1)
                        {
                                printf("egain\n");
                            if(errno == EAGAIN || errno == EINTR)
                            {
                                break;
                            }
                            return -1;
                        }

                        set_nonblock(newfd);

                        usleep(100*1000);
                        printf("new socket coming ....\n");
                    }
                }
            }
        }
    }


    return 0;
}


















