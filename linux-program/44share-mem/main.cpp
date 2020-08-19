#include "../common.h"


int main(int argc, char* argv[])
{
//    int pipefd = open("../a.pipe", O_RDONLY);

    int fd = open("/run/shm/111", O_RDWR);
    void* p = mmap(NULL, 2048*1024, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    sem_t* sem = (sem_t*)p;
    sem_init(sem, 1, 0);

    if(p == MAP_FAILED)
    {
        perror("mmap");
        return 0;
    }
    char* buf = ((char*)p)+1024;
    while(1)
    {
    //    char ch;
    //    read(pipefd, &ch, 1);
        sem_wait(sem);
        // wait the signal SIGCONT
        printf("%s", buf);
        msync(p, 1024, MS_INVALIDATE|MS_SYNC);
    }

    sem_destroy(sem);
    munmap(p, 1024*2048);
    close(fd);
//    close(pipefd);

    return 0;
}


















