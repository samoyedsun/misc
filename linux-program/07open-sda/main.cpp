#include "../common.h"

int main()
{
    int fd = open("/dev/sda", O_RDONLY);

    char buf[1024];
    int ret = read(fd, buf, sizeof(buf));
    printf("%d\n", ret);

    close(fd);
    return 0;
}
