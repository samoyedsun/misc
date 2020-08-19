#include "../common.h"

int main(int argc, char* argv[])
{
    int fd[2];
    int ret = socketpair(AF_UNIX, SOCK_STREAM, 0, fd);
    if(ret < 0)
    {
        perror("socketpair");
        return 0;
    }

    char buf[1024];
    memset(buf, 0, sizeof(buf));

    write(fd[1], "456", 3);
    write(fd[0], "123", 3);

    read(fd[1], buf, sizeof(buf));
    printf("read fd[1]:%s\n", buf);
    read(fd[0], buf, sizeof(buf));
    printf("read fd[0]:%s\n", buf);

    
    return 0;
}


















