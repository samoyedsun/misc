#include "../common.h"

int main()
{
    mylog(LOG_DEBUG, "hello world\n");
//    __mylog1("%s %d %s %s %d", LOG_DEBUG, __FILE__, __LINE__, __func__, "hello world\n", 50);

    return 0;
}
