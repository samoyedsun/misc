#include "../common.h"

int pipeRead;
int pipeWrite;
pthread_t thread;

void create_pipe(int isMaster)
{
    if(isMaster)
    { 
        mkfifo("1.pipe", 0666);
        mkfifo("2.pipe", 0666); 

        pipeRead = open("1.pipe", O_RDONLY);
        pipeWrite = open("2.pipe", O_WRONLY);
    }
    else
    {
        pipeWrite = open("1.pipe", O_WRONLY);
        pipeRead = open("2.pipe", O_RDONLY);
    }
}

void* thread_func(void*)
{
    while(1)
    {
        char buf[2048];
        int ret = read(pipeRead, buf, sizeof(buf));
        if(ret == 0)
            break;
        printf("对方说：%s", buf);
    }
}

void create_thread()
{
    pthread_create(&thread, NULL, thread_func, NULL);
}

void send_message()
{
    while(1)
    {
        char buf[2048];
        fgets(buf, sizeof(buf), stdin);
        if(*buf == '\n')
            continue;

        int ret = write(pipeWrite, buf, strlen(buf)+1);
        // SIGPIPE
        if(ret == -1)
            break;
    }
}

int main(int argc, char* argv[])
{
    signal(SIGPIPE, SIG_IGN);
    /*
     * 初始化环境：创建管道，创建线程
     *
     * 主线程：获取用户输入，发送
     * 子线程：读取管道
     *
     * */

    int isMaster = strcmp(argv[1], "master") == 0;
    create_pipe(isMaster);
    create_thread();
    send_message();

    pthread_join(thread, NULL);
    return 0;
}


















