#include <sys/file.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/types.h>
#include <stdio.h>
#include <unistd.h>

int main()
{
    int fd = open("a", O_RDWR);

    flock(fd, LOCK_EX);

    getchar();

    flock(fd, LOCK_UN);

    while(1)
    {
        sleep(1);
    }

    close(fd);
}
