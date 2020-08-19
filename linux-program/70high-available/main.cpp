#include "../common.h"

void signal_handle(int v)
{
    printf("signal is %d\n", v);
}

int main(int argc, char* argv[])
{
    signal(SIGPIPE, signal_handle);

    unlink("dbg.txt");
    int dbg_fd = open("dbg.txt", O_CREAT|O_APPEND|O_RDWR, 0777);

    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(9989);
    addr.sin_addr.s_addr = 0;

    int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        exit(0);
    }

    listen(fd, 200);
    // 创建子进程
    int process_count = atoi(argv[1]);
    int is_sub_process = 0;
    for(int i=0; i<process_count; ++i)
    {
        pid_t pid = fork();
        if(pid == 0)
        {
            is_sub_process = 1;
            break;
        }
    }

    int epfd = epoll_create(1024);

    struct epoll_event ev;
    ev.data.fd = fd;
    ev.events = EPOLLIN;
    epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);

    int flags = fcntl(fd, F_GETFL);
    flags |= O_NONBLOCK;
    fcntl(fd, F_SETFL, flags);

    if(argc < 2)
    {
        printf("invalid parameter\n");
        exit(1);
    }

    while(1)
    {
        struct epoll_event evs[8];
        int events = epoll_wait(epfd, evs, 8, 5000);
        if(events == 0) continue;
        if(events < 0) 
        {
            if(errno == EINTR) continue;
            printf("epoll_wait error: %s\n", strerror(errno));
            break;

        }

        for(int i=0; i<events; ++i)
        {
            if(evs[i].data.fd == fd)
            {
                while(1)
                {
                    int newfd = accept(fd, NULL, NULL);
                    if(newfd < 0)
                    {
                        if(errno == EAGAIN) break;
                        printf("error is: %s\n", strerror(errno));
                        exit(0);
                    }
                    ev.data.fd = newfd;
                    epoll_ctl(epfd, EPOLL_CTL_ADD, newfd, &ev);
                }
            }
            else
            {
                char buf[1024];
                if(read(evs[i].data.fd, buf, sizeof(buf)) == 0)
                {
                    close(evs[i].data.fd);
                }
                else
                {
//                    printf("pid = %d, recv data is: %s\n", (int)getpid(), buf);
                    write(evs[i].data.fd, "ok", 3);
                    write(dbg_fd, "1", 1);
                }
            }
        }
    }

    close(dbg_fd);

    if(!is_sub_process)
    {
        for(int i=0; i<process_count; ++i)
        {
            wait(NULL);
        }
    }


    return 0;
}


















