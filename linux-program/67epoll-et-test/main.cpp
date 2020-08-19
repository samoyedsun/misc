#include "../common.h"

void test()
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(10991);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    connect(fd, (struct sockaddr*)&addr, sizeof(addr));
}

int main(int argc, char* argv[])
{
    for(int i=0; i<10; ++i)
    {
        pid_t pid = fork();
        if(pid == 0)
        {
            test();
            return 0;
        }
    }


    for(int i=0; i<10; ++i)
    {
        wait(NULL);
    }
    return 0;
}


















