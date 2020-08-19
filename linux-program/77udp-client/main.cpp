#include "../common.h"

int main(int argc, char* argv[])
{
    int sock = socket(AF_INET, SOCK_DGRAM, 0);

    struct sockaddr_in addr;
    addr.sin_addr.s_addr = inet_addr("255.255.255.255");
    addr.sin_port = htons(8899);
    addr.sin_family = AF_INET;

    // 打开socket广播功能
    int optval = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &optval, sizeof(optval));

    char buf[1024] = "hello udp";
    sendto(sock, buf, strlen(buf)+1, 0,
            (struct sockaddr*)&addr, sizeof(addr));

    sendto(sock, buf, strlen(buf)+1, 0,
            (struct sockaddr*)&addr, sizeof(addr));

    read(sock, buf, sizeof(buf));

    printf("%s\n", buf);

    return 0;
}


















