#include "../common.h"

int main()
{
    char* p = getenv("PWD");
    printf("p is %s\n", p);

    printf("HOME is %s\n", getenv("HOME"));
    return 0;
}
