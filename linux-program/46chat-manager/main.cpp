#include "../common.h"

/*
 * create shared memory
 * init sem_t manager
 * init sem_t message
 * */
int main(int argc, char* argv[])
{
    int shared_length = 2048*42;
    unlink("/run/shm/chat.mem");
    int fd = open("/run/shm/chat.mem", O_RDWR|O_CREAT, 0777);
    ftruncate(fd, shared_length);
    void* p = mmap(NULL, shared_length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);

    sem_t* sem = (sem_t*)p;
    sem_init(&sem[0], 1, 1); // 谁抢到这个信号，谁能够写公共区域
    sem_init(&sem[1], 1, 0);  // 这个信号量用于通信，当一个进程写入聊天信息时，要增加信号，增加的数量是当前聊天人数
    sem_init(&sem[2], 1, 1);

    int* chat_count = (int*)(sem+3);
    *chat_count = 0;

    // 所有的用户空间都写成0，表示用户空间还没有人用
    char* start = (char*)p;
    start += 2048;

    for(int i=0; i<39; ++i)
    {
        printf("i=%d\n", i);
        *start = 0;
        start += 2048;
    }

    munmap(p, shared_length);
    close(fd);

    return 0;
}


















