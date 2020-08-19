
#ifndef __COMMON_H__
#define __COMMON_H__

// sockaddr_in 头文件
// inet_addr
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/epoll.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <time.h>
#include <semaphore.h>
#include <pthread.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <utime.h>
#include <stdarg.h>
#include <sys/socket.h>

//#define mylog(fmt, ...) printf("%s %d:" fmt,  __FILE__, __LINE__, ##__VA_ARGS__)
//
#define LOG_DEBUG 1
#define LOG_INFO  2
#define LOG_WARN  3
#define LOG_ERROR 4

#define mylog(level, fmt, ...) __mylog1("%s %d %s " fmt, level, \
    __FILE__, __LINE__, __func__, ##__VA_ARGS__)

void __mylog1(const char* fmt, int level, ...);

int read_data(int sockfd, char* buf, int len);
int write_data(int sockfd, const char* buf, int len);

#endif
