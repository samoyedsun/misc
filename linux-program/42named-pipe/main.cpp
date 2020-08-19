#include "../common.h"

int main(int argc, char* argv[])
{
    int fd = open("../a.pipe", O_WRONLY);
    if(fd < 0)
    {
        perror("open");
        return 0;
    }

    while(1)
    {
        char buf[1024];
        fgets(buf, sizeof(buf), stdin);

        write(fd, buf, strlen(buf)+1);
    }

    return 0;
}


















