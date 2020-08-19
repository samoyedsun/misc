#include "../common.h"

int main(int argc, char* argv[])
{
    // 创建udp socket
    int sock = socket(AF_INET, SOCK_DGRAM, 0);

    // 作为服务器的udp需要绑定端口
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(8899);
    addr.sin_addr.s_addr = 0;
    int ret = bind(sock, (struct sockaddr*)&addr, sizeof(addr));

    // 接收 
    char buf[1024];
    struct sockaddr peer_addr;
    socklen_t addrlen = sizeof(peer_addr);
    ret = recvfrom(sock, buf, 5,
            0, (struct sockaddr*)&peer_addr, &addrlen);

    printf("ret is %d\n", ret);
    printf("%s\n", buf);

    ret = recvfrom(sock, buf, sizeof(buf),
            0, &peer_addr, &addrlen);
    printf("%s\n", buf);

    // 发送
    strcpy(buf, "i got it");
    sendto(sock, buf, strlen(buf)+1, 
            0, &peer_addr, addrlen);

    return 0;
}


















