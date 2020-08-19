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

    char* pread = (char*)mmap(NULL, total_size, PROT_READ, MAP_SHARED, fd_read, 0);
    if(pread == MAP_FAILED)
    {
        perror("map read");
        return 0;
    }

    int fd_write = open(argv[2], O_RDWR|O_CREAT, 0777);
    ftruncate(fd_write, total_size);

    char* pwrite = (char*)mmap(NULL, total_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd_write, 0);
    if(pwrite == MAP_FAILED)
    {
        perror("map write");
        return 0;
    }

    int one_time_copy_size = 1024;
    int copy_times = total_size / one_time_copy_size;

    char* in = pread;
    char* out = pwrite;

    int i;
    for(i=0; i<copy_times; ++i)
    {
        memcpy(out, in, one_time_copy_size);
        out += one_time_copy_size;
        in += one_time_copy_size;
        already_copy += one_time_copy_size;
    }

    memcpy(out, in, total_size % one_time_copy_size);
    already_copy = total_size;

#if 0
    while(1)
    {
        memcpy(pwrite+, pread, one_time_copy_size);

        int ret = read(fd_read, buf, 1024);
        write(fd_write, buf, ret);
        already_copy += ret;

        if(already_copy == total_size)
        {
            break;
        }
    }
#endif

    kill(pid, SIGKILL);
    sig_handle(SIGUSR1); 

    munmap(pread, total_size);
    munmap(pwrite, total_size);
    close(fd_read);
    close(fd_write);

    return 0;
}


















