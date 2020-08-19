#include "../common.h"

int main()
{
    extern char** environ;
    chdir("/");

//    char* path = getenv("PATH");
//    printf("path is %s\n", path);
    for(int i=0; ; ++i)
    {
        char*p = environ[i];
        if(p == NULL)
            break;
        printf("p is %s\n", p);
    }

    return 0;
}
