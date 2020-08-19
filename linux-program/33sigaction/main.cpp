#include "../common.h"


#if 0
struct sigaction {
    void     (*sa_handler)(int);
    void     (*sa_sigaction)(int, siginfo_t *, void *);
    sigset_t   sa_mask;
    int        sa_flags;
    void     (*sa_restorer)(void);
};
#endif

void sig_handle(int, siginfo_t* info, void*)
{
    printf("%d\n", info->si_int);
}

int main(int argc, char* argv[])
{
    struct sigaction sig;
//    struct sigaction oldsig;
//    sigaction(SIGINT, &sig, &oldsig);
    sig.sa_handler = NULL; // 要使用sa_sigaction回调
    sig.sa_sigaction = sig_handle;
    sigemptyset(&sig.sa_mask);
    sig.sa_flags = SA_SIGINFO;
    sig.sa_restorer = NULL;  // 不用了
    sigaction(SIGINT, &sig, NULL);

    // 带参数的发送信号
    sigval_t v;
    v.sival_int = 100;
    sigqueue(getpid(), SIGINT, v);

    sleep(1);

    return 0;
}


















