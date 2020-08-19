#include "../common.h"

double data = 0;

// 锁
pthread_mutex_t lock;

#if 0
void foo_handle_public()
{
    pthread_mutex_lock();
    operate_public();
    pthread_mutex_unlock();
}
#endif

void* thread_func(void*)
{
#if 0
    pthread_mutex_lock();
    foo_handle_public();
    pthread_mutex_unlock();
#endif

    for(int i=0; i<1000000; ++i)
    {
        pthread_mutex_lock(&lock);
        pthread_mutex_lock(&lock);
        data = data + 1;
        pthread_mutex_unlock(&lock);
        pthread_mutex_unlock(&lock);
    }
}

int main(int argc, char* argv[])
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);

    // 设置成循环锁
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);

    pthread_mutex_init(&lock, &attr);

    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);

    for(int i=0; i<1000000; ++i)
    {
        pthread_mutex_lock(&lock);
        data = data + 1;
        pthread_mutex_unlock(&lock);
    }

    pthread_join(thread, NULL);
    printf("data is: %g\n", data);
    return 0;
}


















