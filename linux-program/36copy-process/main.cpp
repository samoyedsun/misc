#include "../common.h"

void notify_process()
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
int one_time_copy = 1024;
int total_size;
void* ppread;
void* ppwrite;

void notify_handle(int)
{
    printf("copy %.2f%%\n", already_copy*100.0f/total_size);
    // 计算百分比并打印
}

void notify_copy(int,siginfo_t* info, void*)
{
    already_copy += info->si_int;
    if(already_copy >= total_size)
    {
        already_copy = total_size;    
        notify_handle(SIGUSR1);
        munmap(ppread, total_size);
        munmap(ppwrite, total_size);
        exit(0);
    }  
}

void do_copy(int idx, int total_process)
{
    pid_t ppid = getppid();
    // total_size
    int piece = total_size / total_process;
    int start = idx * piece;
    // 解决文件长度不整除进程数量的问题
    if(idx == total_process - 1)
    {
        piece = total_size - start;
    }

    char* from = (char*)ppread + start;
    char* to = (char*)ppwrite + start;

    int count = piece / one_time_copy;
    int i;
    for(i=0; i<count; ++i)
    {
        memcpy(to, from, one_time_copy);
        from += one_time_copy;
        to += one_time_copy;

        sigval_t v;
        v.sival_int = one_time_copy;
        sigqueue(ppid, 35, v);
    }

    int remain = piece % one_time_copy;
    if(remain)
    {
        memcpy(to, from, remain);
        sigval_t v;
        v.sival_int = remain;
        sigqueue(ppid, 35, v);
    }
}

void create_copy_process(int count)
{
    for(int i=0; i<count; ++i)
    {
        pid_t pid = fork();
        if(pid == 0)
        {
            do_copy(i, count);
            exit(0);
        }
    }
}

void open_mmap(const char* from, const char* to)
{
    int fd_read = open(from, O_RDONLY);
    struct stat stat_buf;
    fstat(fd_read, &stat_buf);
    total_size = stat_buf.st_size;

    ppread = (char*)mmap(NULL, total_size, PROT_READ, MAP_SHARED, fd_read, 0);
    if(ppread == MAP_FAILED)
    {
        perror("map read");
        exit(0);
    }

    unlink(to);
    int fd_write = open(to, O_RDWR|O_CREAT, 0777);
    ftruncate(fd_write, total_size);

    ppwrite = (char*)mmap(NULL, total_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd_write, 0);
    if(ppwrite == MAP_FAILED)
    {
        perror("map write");
        exit(0);
    }

    close(fd_read);
    close(fd_write);
}

int main(int argc, char* argv[])
{
    pid_t pid = fork();
    if(pid == 0)
    {
        notify_process();
        return 0;
    }

    open_mmap(argv[1], argv[2]);
    create_copy_process(4);

    signal(SIGUSR1, notify_handle);
    //  signal(SIGUSR2, notify_copy);
    struct sigaction sig;
    sig.sa_handler = NULL;
    sig.sa_sigaction = notify_copy;
    sig.sa_flags = SA_SIGINFO;
    sigemptyset(&sig.sa_mask);
    sig.sa_restorer = NULL;
    sigaction(35, &sig, NULL);


    while(1)
    {
        sleep(1);
    }

    return 0;
}


















