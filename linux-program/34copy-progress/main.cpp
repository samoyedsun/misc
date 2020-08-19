#include "../common.h"

void child_process()
{
    pid_t ppid = getppid();
    while(1)
    {
        sleep(1);
        if(kill(ppid, SIGUSR1) == -1)
        {
            break;
        }
    }
}

int already_copy = 0;
int total_size;

void sig_handle(int)
{
    printf("copy %.2f%%\n", already_copy*100.0f/total_size);
    // 计算百分比并打印
}

int main(int argc, char* argv[])
{
    pid_t pid = fork();
    if(pid == 0)
    {
        child_process();
        return 0;
    }

    signal(SIGUSR1, sig_handle);

    // 直接拷贝
    int fd_read = open(argv[1], O_RDONLY);
    struct stat stat_buf;
    fstat(fd_read, &stat_buf);
    total_size = stat_buf.st_size;

    int fd_write = open(argv[2], O_RDWR|O_CREAT, 0777);
    char buf[1024];

    while(1)
    {
        int ret = read(fd_read, buf, 1024);
        write(fd_write, buf, ret);
        already_copy += ret;

        if(already_copy == total_size)
        {
            break;
        }
    }

    kill(pid, SIGKILL);
    sig_handle(SIGUSR1); 

    close(fd_read);
    close(fd_write);

    return 0;
}


















