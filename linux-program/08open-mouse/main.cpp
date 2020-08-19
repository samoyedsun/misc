#include "../common.h"

int main()
{
    int fd = open("/dev/input/mice", O_RDONLY|O_NONBLOCK);

    char buf[16];
    int ret = read(fd, buf, sizeof(buf));
    printf("ret = %d\n", ret);

    if(ret == -1 && errno == EAGAIN)
    {
        printf("不是真的错误，而是非阻塞导致\n");
    }

    close(fd);
    return 0;
}
