#include "../common.h"

int main(int argc, char* argv[])
{
    int fd = open("../a.pipe", O_RDONLY);
    if(fd < 0)
    {
        perror("open");
        return 0;
    }

    while(1)
    {
        char buf[1024];
        if(read(fd, buf, sizeof(buf)) == 0)
            break;
        printf("%s", buf);
    }
    return 0;
}


















