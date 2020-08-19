#include "../common.h"

int main(int argc, char* argv[])
{
#if 0
    // 把一个进程当文件用
    FILE* fp = popen("/home/xueguoliang/a.out", "w");

    fprintf(fp, "3\n");
    fprintf(fp, "5\n");

    pclose(fp);
#endif

#if 1
    // ifconfig | grep inet | grep -v inet6 | awk '{print $2}' | awk -F : '{print $2}
    FILE* fp = popen("ifconfig | grep inet | grep -v inet6 | awk '{print $2}' | awk -F : '{print $2}'", "r");
    char buf[1024];
    memset(buf, 0, sizeof(buf));

    fread(buf, 1, sizeof(buf), fp);

    printf("%s\n", buf);

    pclose(fp);
#endif

    return 0;
}


















