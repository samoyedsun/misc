#include "../common.h"

int main(int argc, char* argv[])
{
    // socket函数创建一个socket对象，而socket对象是一个文件描述符
    // 创建socket需要三个参数
    //  AF_INET协议族类型
    //  SOCK_STREAM/SOCK_DGRAM，在AF_INET协议族下，只支持两个协议类型（TCP/UDP)
    // socket网络编程库是为所有的网络提供编程支持，而不是只为了TCP/IP
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    
    // 绑定端口
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    // htons，h是host，n是net的意思
    // htons是主机序转网络序，s是short
    addr.sin_port = htons(9988);
    // ip地址，ipv4的地址其实是一个32位的整数
    // 192.168.0.255
    // 指定哪个网口，这个值是0的话，表示任何都可以
    addr.sin_addr.s_addr = 0;

    // 通过bind函数绑定一个端口
    // 第一个参数是socket描述符
    // 第二个参数是绑定的地址（其中包含了端口）
    // 第三个参数是地址结构体的长度
    int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));

    // 进入监听状态
    // 第二个参数表示监听的缓冲区
    ret = listen(fd, 5);

    // 接收连接，后面两个参数可以获得对方地址
    // 接收链接成功之后会产生新的socket
    // 这个socket才是真正用来通信的socket
    // accept函数会阻塞，如果缓冲区数据
    int fd_connect = accept(fd, NULL, NULL);

    char buf[1024];
    // 如果缓冲区没有数据，那么read会阻塞
    ret = read(fd_connect, buf, sizeof(buf));
    printf("recv data is %s\n", buf);

    // write函数，将数据写入写缓冲，如果缓冲区没有空间
    // 也会阻塞
    ret = write(fd_connect, "i got it", sizeof("i got it"));

    close(fd_connect);
    close(fd);

    return 0;
}


















