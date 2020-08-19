#include "../common.h"

int main(int argc, char* argv[])
{
    int shared_length = 2048*42;
    int fd = open("/run/shm/chat.mem", O_RDWR);
    void* p = mmap(NULL, shared_length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if(p == MAP_FAILED)
    {
        perror("mmap");
        return 0;
    }

    sem_t* sem = (sem_t*)p;

    sem_wait(sem);
    int* chat_count = (int*)(sem+3);
    *chat_count = *chat_count+1;

    printf("now chat_count is %d\n", *chat_count);

    // 寻找一个空位置
    char* start = (char*)p;
    start += 2048; // 前面2048字节给管理用

    // 每隔2048个字节是一个用户空间
    // 第一个字节表示这个用户空间的状态
    // 0表示空置
    // 1表示有人用，但是没有信息消息
    // 2 表示这个位置有人发消
    while(1)
    {
        if(*start == 0)
        {
            *start = 1;
            break;
        }
        start+=2048;
    }
    printf("start pos is %d\n", (int)(start - (char*)p));

    sem_post(sem); // 供别的用户继续抢管理数据权限

    pid_t pid = fork();
    if(pid == 0)
    {
        while(1)
        {
            wait(sem+1);
            char* user = (char*)p;
            user += 2048;
            for(int i=0; i<39; ++i)
            {
                if(*user > 1)
                {
                    printf("%s说: %s", user+1, user+8);
                    sem_wait(sem+2);
                    *user = *user -1;
                    sem_post(sem+2);
                }
                user += 2048;
            }

            usleep(100*1000);
        }

        return 0;
    }

    strncpy(start+1, argv[1], 6);
    start[7] = 0;

    while(1)
    {
        fgets(start+8, 2040, stdin);

        sem_wait(sem);
        *start = *start + *chat_count;
        for(int i=0; i<*chat_count; ++i)
        {
            sem_post(sem+1);
        }
        usleep(100*1000);
        sem_post(sem);
    }

    return 0;
}


















