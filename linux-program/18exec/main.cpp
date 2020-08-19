#include "../common.h"


int main()
{

    int fd = open("a.txt", O_CREAT|O_WRONLY|O_CLOEXEC, 0777);

    const char *env[] = 
    {
        "PWD=/",
        NULL
    };

    int ret = execle("../19test/19test.bin", "../19test/19test.bin", NULL, env);

 //   int ret = execlp("who", "who", NULL);
    if(ret == 0)
    {
        printf("sucess\n");
    }
    else
    {
        printf("error\n");
    }
    printf("sadfsdfsdfsdfsd");
    return 0;
}
