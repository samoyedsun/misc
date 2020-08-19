#include "../common.h"
#include <list>

// 全局需要有一个队列，用于主线和子线程的数据交换
// 队列中的数据一定要从堆上申请
std::list<char*> data_queue;

// 锁
pthread_mutex_t mutex;

// 信号量，看成是一个整数
sem_t sem;

void* thread_func(void*)
{
    pthread_t self = pthread_self();

    while(1)
    {
        // 子线程等待主线程的信号，这个函数在信号量没有信号的时候，会阻塞
        int ret = sem_wait(&sem);
        if(ret < 0)
        {
            if(errno == EINTR)
                continue;
            break;
        }

        // data_queue.size()究竟要不要加锁,
        // 在有多个工作线程情况
        pthread_mutex_lock(&mutex);
        if(data_queue.size() > 0)
        {
            std::list<char*>::iterator it = data_queue.begin();
            char* data = *it;
            data_queue.erase(it);
            pthread_mutex_unlock(&mutex);

            // 此处省略很多代码
            printf("%d, %s", (int)self, data);
            free(data);
        }
        else
        {
            pthread_mutex_unlock(&mutex);
        }
    }
}

int main(int argc, char* argv[])
{

    pthread_mutex_init(&mutex, NULL);
    sem_init(&sem, 
            0, //表示这个信号量是线程（同一个进程的线程）之间用的
          0);

    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_create(&thread, NULL, thread_func, NULL);
    pthread_create(&thread, NULL, thread_func, NULL);

    while(1)
    {
        char buf[1024];
        fgets(buf, sizeof(buf), stdin);

        // this is error，buf不能直接放入队列中，因为它是栈变量
        // data_queue.push_back(buf);
        pthread_mutex_lock(&mutex);
        data_queue.push_back(strdup(buf));
        pthread_mutex_unlock(&mutex);

        // 告诉子线程，你可以开工了
        sem_post(&sem);
    }
    return 0;
}


















