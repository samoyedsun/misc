#include "../common.h"

int main()
{
    int fd = open("a.txt", O_WRONLY);
    int fd1 = open("a.txt", O_WRONLY);

    write(fd, "abc", 3);

    lseek(fd1, 3, SEEK_SET);
    write(fd1, "xxx", 3);

    close(fd);
    close(fd1);

    return 0;
}
