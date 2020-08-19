#include "../common.h"
#include <iostream>
using namespace std;

int main1()
{
    // 将1描述符的内容，写入到fd指订的数据结构中
    int fd = dup(1);
    char buf[] = "hello world\n";
    write(fd, buf, sizeof(buf));

    close(fd);

    return 0;
}

int main2()
{
    int fd = open("a.txt", O_WRONLY|O_CREAT, 0777);
    dup2(fd, 1);
    close(fd);

    printf("hello world\n");
    return 0;
}

int main()
{
    // 保存标准输出描述符
    int saved = dup(1);

    // 创建重定向文件 
    unlink("a.txt");
    int redir = open("a.txt", O_RDWR|O_APPEND|O_CREAT, 0777);

    // 重定向
    int ret = dup2(redir, 1);
    close(redir);
    // 输出内容，这个内容输出到重定向文件中
    printf("write to file\n");
    fflush(stdout);

    // 重定向回来
    dup2(saved, 1);
    printf("write to terminal\n");

    close(saved);

    return 0;
}

int main3()
{
    char buf[] = "/tmp/666XXXXXX7777";
    int ret = mkstemps(buf, 4);
    printf("%s\n", buf);
}



