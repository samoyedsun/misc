#include <sys/file.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/types.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

int main()
{
    int fd = open("../a", O_RDWR);

    struct flock lock;
    memset(&lock, 0, sizeof(lock));

    // lock
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    lock.l_start = 0;
    lock.l_len = 10;
    lock.l_pid = getpid();
    fcntl(fd, F_SETLK, &lock);

    // wait for user input
    getchar();

    // unlock 
    lock.l_type = F_UNLCK;
    fcntl(fd, F_SETLK, &lock);

    while(1)
    {
        sleep(1);
    }

    close(fd);
}
