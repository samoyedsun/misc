#include "../common.h"
#include <sys/un.h>

int main(int argc, char* argv[])
{
    int sock = socket(PF_UNIX, SOCK_DGRAM, 0);

    struct sockaddr_un addr;
    addr.sun_family = AF_UNIX;
    strcpy(addr.sun_path, "/tmp/XXXXXX");
    mkstemp(addr.sun_path);

    unlink(addr.sun_path);

    int ret = bind(sock, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 0;
    }

    struct sockaddr_un peeraddr;
    peeraddr.sun_family = AF_UNIX;
    strcpy(peeraddr.sun_path, "/tmp/local-socket");

    // udp的连接表示调用send时，默认发送这个地址
    connect(sock, (struct sockaddr*)&peeraddr, sizeof(peeraddr));

    char buf[] = "ba gu is a bad egg";
    send(sock, buf, sizeof(buf), 0);
//    sendto(sock, buf, sizeof(buf), 0, (struct sockaddr*)&peeraddr, sizeof(peeraddr));
    
    char resp[1024];
    recv(sock, resp, sizeof(resp), 0);

    printf("resp = %s\n", resp);

}

#if 0
int main(int argc, char* argv[])
{
    int sock = socket(PF_UNIX, SOCK_STREAM, 0);

    // connect
    struct sockaddr_un addr;
    addr.sun_family = PF_UNIX;
    strcpy(addr.sun_path, "/tmp/local-socket");

    int ret = connect(sock, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("connect\n");
        return 0;
    }

    char buf[] = "hello local socket";
    send(sock, buf, sizeof(buf), 0);

    close(sock);

    return 0;
}
#endif

















