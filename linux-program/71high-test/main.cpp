#include "../common.h"

void test()
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(9989);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    connect(fd, (struct sockaddr*)&addr, sizeof(addr));

    send(fd, "1", 2, 0);
    
    char buf[1024];
    recv(fd, buf, sizeof(buf), 0);
}

int main(int argc, char* argv[])
{
#if 1
    for(int i=0; i<20000; ++i)
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
#endif
    return 0;
}


















