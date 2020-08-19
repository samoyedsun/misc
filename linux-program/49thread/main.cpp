#include "../common.h"

#if 0
// 线程入口函数
void* thread_main(void* arg)
{
    sleep(5);
    printf("hello thread\n");
    return (void*)2;
}

int main(int argc, char* argv[])
{
    pthread_t thread;
    pthread_create(&thread, NULL, thread_main, NULL);

    sleep(1);
    pthread_cancel(thread);

    // 只是等待线程结束，但是不关心它的返回值
    //pthread_join(thread, NULL);


    // 等待线程结束，并且获得线程的返回值
    void* thread_ret_value;
    pthread_join(thread, &thread_ret_value);
    printf("ret is %p\n", thread_ret_value);

    return 0;
}

#endif


#if 0
// 我常用的退出线程方法
int quit = 0;
void* thread_main(void* arg)
{
    while(1)
    {
        if(quit == 1)
            break;

        sleep(1);
        printf("hello thread\n");
    }
}

int main()
{
    pthread_t thread;
    pthread_create(&thread, NULL, thread_main, NULL);

    getchar();

    quit = 1;
//    pthread_cancel(thread);
    pthread_join(thread, NULL);
}
#endif


#if 0
// 演示安全的cancel
void* thread_func(void*)
{
    int i = 0;
    while(1)
    {
        pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL);

        // 此处省略1万行

        pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
        pthread_testcancel(); // 是一个退出点，所以不用管返回值
    }
} 

int main()
{
    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);
    // 此处省略很多代码
    //
    pthread_cancel(thread);
}
#endif

#if 0
// 演示pthread_self和pthread_equal
// 全局变量保存三个线程号
pthread_t main_thread;
pthread_t thread1;
pthread_t thread2;

void get_input_and_output()
{
    pthread_t self = pthread_self();

    char buf[1024];
    while(1)
    {
        fgets(buf, sizeof(buf), stdin);
     //   buf[strlen(buf)-1] = 0;  // 把\n去掉
    
        if(pthread_equal(self, main_thread))
        {
            printf("main thread get data, buf is %s", buf);
        }
        else if(pthread_equal(self, thread1))
        {
            printf("thread1 get the data, buf is %s", buf);
        }
        else if(pthread_equal(self, thread2))
        {
            printf("thread2 get the data, buf is %s", buf);
        }
        else
        {
            perror("bug is here");
            exit(0);
        }
    }
}

void* thread_func(void*arg)
{
    get_input_and_output();
}

// 主线程负责初始化三个线程编号
int main()
{
    main_thread = pthread_self();

    pthread_create(&thread1, NULL, thread_func, NULL);
    pthread_create(&thread2, NULL, thread_func, NULL);

    get_input_and_output();
    return 0;
}

#endif

#if 0
/// 演示pthread_detach
void* thread_func(void*)
{
    sleep(1);
    return (void*)2;
}

int main()
{
    pthread_t threadid;
    pthread_create(&threadid, NULL, thread_func, NULL);

    pthread_detach(threadid);

//    sleep(1);

    void* ret_value;
    int ret = pthread_join(threadid, &ret_value);
    printf("ret_value is %p\n", ret_value);
    if(ret == EINVAL)
    {
        printf("this is not joinable thread\n");
    }
    return 0;
}

#endif

#if 1

void* p;
int fd;
void* thread_func(void*)
{
    free(p); 
 //   munmap(p);
}

int main()
{

    // 定义线程属性对象
    pthread_attr_t attr;
    // 初始化
    pthread_attr_init(&attr);

    // 可以通过修改attr来修改线程的属性
    p = malloc(100);
//    fd = open(...);
  //  p = mmap(....);

    pthread_t thread;
    pthread_create(&thread, &attr, thread_func, NULL);

    while(1)
    {
        sleep(1);
    }
    return 0;
}


#endif










