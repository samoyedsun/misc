
#include "common.h"

void __mylog1(const char* fmt, int level, ...)
{
    char buf[4096];
    va_list ap;
    va_start(ap, level);
    vsprintf(buf, fmt, ap);
    va_end(ap);

    char type[] = "DIWE";

    printf("%c %s", type[level-1],  buf);
}

// 封装socket的发送和接收函数，保证用户要求的内容被充分发送或者接收
int read_data(int sockfd, char* buf, int len)
{
    int recved = 0;
    int wanted = len;
    while(wanted > 0)
    {
        int ret = read(sockfd, buf+recved, wanted);

        if(ret == 0)
            return 0;
        if(ret == -1)
        {
           if(errno == EINTR) 
              continue;
            return ret; 
        }

        recved += ret;
        wanted -= ret;
    }
    return len;
}

int write_data(int sockfd, const char* buf, int len)
{
    int sended = 0;
    int wanted = len;
    while(wanted > 0)
    {
        int ret = write(sockfd, buf + sended, wanted);
        if(ret < 0)
        {
            if(errno == EINTR)
                continue;
            return ret;
        }

        sended += ret;
        wanted -= ret;
    }
    return len;
}

#if 0
int read_data(int sockfd, char* buf, int len)
{
    int already_recved = 0;
    int wanted_length = len;  // 100
AGAIN:
    // ret = 5
    int ret = read(sockfd, buf+already_recved, 
            wanted_length);

    if(ret == 0)
        return 0;
    if(ret == wanted_length)
        return len; // 表示全部收到了
    if(ret < 0)
    {
        if(errno == EINTR)
        {
            goto AGAIN;
        }
        return ret;
    }
    if(ret < wanted_length)
    {
        wanted_length -= ret;
        already_recved += ret;
        goto AGAIN; 
    }
}
#endif
