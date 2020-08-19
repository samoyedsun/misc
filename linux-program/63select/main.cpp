#include "../common.h"

#define key_board_file "/dev/input/event3"

int main(int argc, char* argv[])
{
    int fd_mouse = open("/dev/input/mice", O_RDONLY);
    if(fd_mouse < 0)
    {
        perror("open mouse");
        return 0;
    }
    int fd_keyboard = open(key_board_file, O_RDONLY);
    if(fd_keyboard < 0)
    {
        perror("open keyboard");
        return 0;
    }
#if 0
    // 问题在于有多个阻塞点
    while(1)
    {
        char mouse[8];
        read(fd_mouse, mouse, sizeof(mouse));

        char key[8];
        read(fd_keyboard, key, sizeof(key));
    }
#endif

    while(1)
    {
        // 三个参数，maxfd, readfds, timeval
        int maxfd;
        fd_set readfds;
      //  struct timeval tv;

        // timeval一秒
        tv.tv_sec = 1;
        tv.tv_usec = 0;

        // 处理集合，把鼠标键盘文件描述符放入集合中
        FD_ZERO(&readfds);
        FD_SET(fd_keyboard, &readfds);
        FD_SET(fd_mouse, &readfds);

        // 获得最大的文件描述符
        maxfd = fd_keyboard;
        if(maxfd < fd_mouse)
            maxfd = fd_mouse;
        maxfd ++;

        // 调用select阻塞等待集合中文件描述符的信号
        int ret = select(maxfd, &readfds, NULL, NULL, &tv);

        // 最后一个参数如果NULL，那么就是死等
      //  int ret = select(maxfd, &readfds, NULL, NULL, NULL);
        if(ret == -1)
        {
            if(errno == EINTR)
                continue;
            break;
        }
        else if(ret > 0)
        {
            if(FD_ISSET(fd_mouse, &readfds))
            {
                char buf[8];
                read(fd_mouse, buf, sizeof(buf));
                printf("mouse event handle\n");
            }
            if(FD_ISSET(fd_keyboard, &readfds))
            {
                char buf[8];
                read(fd_keyboard, buf, sizeof(buf));
                printf("keyboard event handle\n");
            } 
        }
    }

    return 0;
}


















