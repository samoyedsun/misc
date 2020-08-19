#include "../common.h"

void sighandle(int sig, siginfo_t *siginfo, void * data)
{
    printf("data is %d\n", siginfo->si_int);
    printf("data is %d\n", siginfo->si_value.sival_int);
}


#if 0
struct sigaction {
    void     (*sa_handler)(int);
    void     (*sa_sigaction)(int, siginfo_t *, void *);
    sigset_t   sa_mask;
    int        sa_flags;
    void     (*sa_restorer)(void);
};
#endif


int main(int argc, char* argv[])
{
    struct sigaction usr1;
    /* 注册信号 */
    usr1.sa_handler = NULL;
    usr1.sa_sigaction = sighandle;
//    sigemptyset(&usr1.sa_mask);
//    sigfillset(&usr1.sa_mask);
    sigemptyset(&usr1.sa_mask);
    sigaddset(&usr1.sa_mask, SIGUSR2);
    usr1.sa_flags = SA_RESTART|SA_SIGINFO;
    usr1.sa_restorer = NULL;

    sigaction(SIGUSR1, &usr1, NULL);


    pid_t pid = fork();
    if(pid == 0)
    {
        sleep(1);

        union sigval v;
        /* 发送信号 */
        v.sival_int = 100;
        sigqueue(getppid(), SIGUSR1, v);
        return 0;
    }

    int fd = open("/dev/input/mice", O_RDONLY);
    char buf[8];
    /* 读取鼠标，阻塞的调用 */
    int ret = read(fd, buf, sizeof(buf));

    printf("ret is %d, err string is %s\n", ret, strerror(errno));

    return 0;
}

















