#include "../common.h"

void foo();
int fd_dbg;
int main(int argc, char* argv[])
{
    int count = atoi(argv[1]);
    fd_dbg = open("log.txt", O_CREAT|O_TRUNC|O_APPEND, 0777);

    for(int i=0 ; i<count; ++i)
    {
        pid_t pid = fork();
        if(pid == 0)
        {
            foo();
            return 0;
        }
    }

    for(int i=0; i<count; ++i)
    {
        wait(NULL);
    }
    return 0;
}

void foo()
{
    // 创建socket
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    // 虽然客户端没有调用bind，但是客户端事实上是有端口的
    // 这个端口由操作系统随机分配一个

    // 指定服务器地址，连接服务器
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    // 客户端指定的端口和服务器需要一致
    addr.sin_port = htons(9988);
    // 客户端制定的ip地址，是服务器的ip地址
    addr.sin_addr.s_addr = inet_addr("192.168.155.51");

    // 这个是阻塞调用，连接服务器需要多次的协商过程，所以不是瞬间完成的
    int ret = connect(fd, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        printf("error connect\n");
        write(fd_dbg, "1", 1);
        return;    
    }

    // 和服务器的read/write没有区别
    write(fd, "hello server", sizeof("hello server"));

    char buf[1024];
    ret = read(fd, buf, sizeof(buf));
    if(ret <= 0)
    {
        write(fd_dbg, "1", 1);
        printf("error read\n");
        return;
    }

    printf("%s\n", buf);
    close(fd);

    return;
}


















