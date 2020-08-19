#include "../common.h"

int main(int argc, char* argv[])
{
    int server = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_port = htons(8080);  // 80已经被apache占用
    addr.sin_addr.s_addr = 0;
    addr.sin_family = AF_INET;

    int ret = bind(server, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 1;
    }

    listen(server, 5);

    int newfd = accept(server, NULL, NULL);

    char buf[8192];
    memset(buf, 0, sizeof(buf));
    recv(newfd, buf, sizeof(buf), 0);

    printf("%s", buf);

    return 0;
}


















