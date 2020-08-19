#include "../common.h"

int main()
{
    int fd = open("a.txt", O_CREAT|O_EXCL, 0777);

    if(fd < 0)
    {
        printf("instance has already exist\n");
        return 1;
    }

    while(1)
    {
        sleep(1);
    }

    unlink("a.txt");


    return 0;
}
