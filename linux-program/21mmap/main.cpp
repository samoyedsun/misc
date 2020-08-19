#include "../common.h"

int main(int argc, char* argv[])
{
    int fd = open("a.txt", O_RDWR);
    if(fd < 0)
    {
        perror("open");
        return 0;
    }

    // 将打开的文件，映射到虚拟内存地址
    void* p = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if(p == MAP_FAILED)
    {
        perror("mmap");
        return 0;
    }

    *(char*)p = 'a';
    strcpy((char*)p, "hello map\n");

    munmap(p, 4096);    

    close(fd);

    return 0;
}


















