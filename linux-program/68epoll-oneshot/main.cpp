#include "../common.h"
#include <list>

void epoll_add(int epfd, int sockfd, int e)
{
    struct epoll_event ev;
    ev.events = e;
    ev.data.fd = sockfd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, sockfd, &ev);
}

void epoll_mod(int epfd, int sockfd, int e)
{
    struct epoll_event ev;
    ev.events = e;
    ev.data.fd = sockfd;
    epoll_ctl(epfd, EPOLL_CTL_MOD, sockfd, &ev);
}
#if 0
void set_nonblock(int fd)
{
    int ret = fcntl(fd, F_GETFL, 0);
    ret |= O_NONBLOCK;
    fcntl(fd, F_SETFL, ret);
}
#endif

std::list<int> fd_queue;
pthread_mutex_t lock;
sem_t sem;

void* thread_func(void*arg)
{
    while(1)
    {
        int fd;
        sem_wait(&sem);
        
        pthread_mutex_lock(&lock);
        fd = *fd_queue.begin();
        fd_queue.pop_front();
        pthread_mutex_unlock(&lock); 

        // 对fd收数据...
        //recv(fd, buf, sizeof(buf));
        printf("data is comming...\n");
        // 处理数据，省略100万行
//        epoll_mod(epfd, fd, EPOLLIN|EPOLLONESHOT);
    }
}

int main(int argc, char* argv[])
{

    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_mutex_init(&lock, NULL);
    sem_init(&sem, 0, 0);

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
    epoll_add(epfd, fd, EPOLLIN);

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
                    int newfd = accept(fd, NULL, NULL);
                    epoll_add(epfd, newfd, EPOLLIN|EPOLLONESHOT);
                }
                else
                {
                    // 将客户端连接的socket发送给线程
                    // 在线程中调用read处理数据
                    pthread_mutex_lock(&lock);
                    fd_queue.push_back(ev[i].data.fd);
                    pthread_mutex_unlock(&lock);
                    sem_post(&sem);
                }
            }
        }
    }

    return 0;
}


















