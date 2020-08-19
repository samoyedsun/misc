#include "../common.h"

int main(int argc, char* argv[])
{
    int sock = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(80);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    int ret = connect(sock, (struct sockaddr*)&addr, sizeof(addr));

    char buf[] = "GET /index.html HTTP/1.1\r\n"
        "Host: localhost\r\n"
        "Connection: keep-alive\r\n"
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\n"
        "Upgrade-Insecure-Requests: 1\r\n"
        "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.75 Safari/537.36\r\n"
        "Accept-Encoding: gzip, deflate, sdch\r\n"
        "Accept-Language: zh-CN,zh;q=0.8\r\n"
        "\r\n";

    write(sock, buf, sizeof(buf));

    char response[8192];
    memset(response, 0, sizeof(response));
    read(sock, response, sizeof(response));
    printf("%s\n", response);

    return 0;
}


















