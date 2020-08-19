#include "../common.h"

/* test open with O_APPEND */
int main()
{
    int fd = open("a.txt", O_RDWR|O_APPEND);

#if 0
    char buf[1024];
    memset(buf, 0, sizeof(buf));
    int ret = read(fd, buf, sizeof(buf));

    printf("%s, ret=%d\n", buf, ret);
#endif

    write(fd, "bcd", 3);

    // 把文件指针放在文件开头
    lseek(fd, 0, SEEK_SET);

    write(fd, "xxx", 3);

    close(fd);
    return 0;
}

int main1()
{
    for(int i=0; ;++i)
    {
    int fd = open("a.txt", O_RDONLY|O_NOFOLLOW);
    if(fd < 0)
        return 0;
    printf("fd is %d\n", fd);
    }

#if 0
    if(fd < 0)
    {
        printf("errno is %d\n", errno);
        perror("open");
        return 0;
    }
    char buf[1024];
    memset(buf, 0, sizeof(buf));
    int ret = read(fd, buf, sizeof(buf));
    printf("%s, %d\n", buf, ret);
    close(fd);

#endif
    return 0;
}
