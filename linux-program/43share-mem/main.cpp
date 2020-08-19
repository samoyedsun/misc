#include "../common.h"

int main(int argc, char* argv[])
{
    int fd = open("/run/shm/111", O_RDWR);
 //   int pipefd = open("../a.pipe", O_WRONLY);

    void* p = mmap(NULL, 2048*1024, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);

    sem_t* sem = (sem_t*)p;

    if(p == MAP_FAILED)
    {
        perror("mmap");
        return 0;
    }

    char* buf = ((char*)p) + 1024;
    memset(buf, 0, 1024);
    while(1)
    {
        fgets(buf, 1024, stdin);
        // 保证数据写入
        msync(p, 2048, MS_INVALIDATE | MS_SYNC);
        sem_post(sem);
  //      write(pipefd, "1", 1);
    }

    sem_destroy(sem);
    munmap(p, 1024*2048);
    close(fd);
//    close(pipefd);
    return 0;
}


















