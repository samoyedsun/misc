#include "../common.h"
#include <list>
// 1. cond只有0和1两种状态，而信号量的状态可以累计
// 2. cond发送信号两种，signal，brocast

std::list<char*> data_queue;
pthread_mutex_t data_mutex;

pthread_cond_t cond;
pthread_mutex_t cond_mutex;

void* thread_func(void*)
{
    while(1)
    {
        sleep(5);
        pthread_mutex_lock(&cond_mutex);
        pthread_cond_wait(&cond, &cond_mutex);
        pthread_mutex_unlock(&cond_mutex);

        while(1)
        {
            pthread_mutex_lock(&data_mutex);
            if(data_queue.size() > 0)
            {
                auto it = data_queue.begin();
                char* data = *it;
                data_queue.erase(it);
                pthread_mutex_unlock(&data_mutex);

                // 处理数据
                printf("data is %s", data);
                free(data);
            }
            else
            {
                pthread_mutex_unlock(&data_mutex);
                break;
            }
        }
    }
}

int main(int argc, char* argv[])
{
    pthread_cond_init(&cond, NULL);
    pthread_mutex_init(&cond_mutex, NULL);

    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);

    while(1)
    {
        char buf[1024];
        fgets(buf, sizeof(buf), stdin);
        pthread_mutex_lock(&data_mutex);
        data_queue.push_back(strdup(buf));
        pthread_mutex_unlock(&data_mutex);

        //pthread_cond_brocast(&cond);
    }

    return 0;
}


















