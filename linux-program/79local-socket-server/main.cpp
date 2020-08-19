#include "../common.h"
#include <sys/un.h>

int main(int argc, char* argv[])
{
    int sock = socket(PF_UNIX, SOCK_DGRAM, 0);

    unlink("/tmp/local-socket");

    // bind地址
    struct sockaddr_un addr;
    addr.sun_family = PF_UNIX;
    // addr.sun_path是有长度限制的，大约120左右
    strcpy(addr.sun_path, "/tmp/local-socket"); 

    int ret = bind(sock, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 0;
    }

    struct sockaddr peeraddr;
    socklen_t addrlen = sizeof(peeraddr);

    char buf[1024];
    ret = recvfrom(sock, buf, sizeof(buf), 0, &peeraddr, &addrlen);
    printf("recv data is %s, ret=%d\n", buf, ret);

    printf("peeraddr is: %s\n", ((struct sockaddr_un*)&peeraddr)->sun_path);

    char resp[] = "i think so!";
    ret = sendto(sock, resp, sizeof(resp), 0, &peeraddr, addrlen); 
    printf("sendto ret=%d\n", ret);
}

#if 0
// TCP 临时套接字
int main(int argc, char* argv[])
{
    // local socket 本地套接字
    int sock = socket(PF_UNIX, SOCK_STREAM, 0);

    unlink("/tmp/local-socket");

    // bind地址
    struct sockaddr_un addr;
    addr.sun_family = PF_UNIX;
    // addr.sun_path是有长度限制的，大约120左右
    strcpy(addr.sun_path, "/tmp/local-socket"); 

    int ret = bind(sock, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 0;
    }

    listen(sock, 5);

    int newfd = accept(sock, NULL, NULL);
    if(newfd == -1)
    {
        perror("accept");
        return 0;
    }

    char buf[1024];
    ret = recv(newfd, buf, sizeof(buf), 0);
    printf("recv data is %s, ret=%d\n", buf, ret);

    return 0;
}

#endif
















