#include "../common.h"
#include <list>
using namespace std;

// 对象池类
template<class T>
class ObjectPool
{
    public:
        static T* getObject()
        {
            T* ret;
            pthread_mutex_lock(&mutex);
            if(freeObjects.size() > 0)
            {
                ret = *freeObjects.begin();
                freeObjects.pop_front();
            }
            else
            {
                ret = new T;
            }    
            pthread_mutex_unlock(&mutex);

            return ret;
        }

        static void freeObject(T* object)
        {
            pthread_mutex_lock(&mutex);
            freeObjects.push_back(object);
            pthread_mutex_unlock(&mutex);
        }

    public:
        static list<T*> freeObjects;
        static pthread_mutex_t mutex;
};

//template<class T>
//list<T*> ObjectPool<T>::freeObjects;

// 模板静态成员变量定义
template<class T>
list<T*> ObjectPool<T>::freeObjects;
template<class T>
pthread_mutex_t ObjectPool<T>::mutex = PTHREAD_MUTEX_INITIALIZER;


/* 设计主线程和子线程的通信结构 */
class DataObject
{
    public:
        char buf[2048];
};
// 主线程和子线程的队列
list<DataObject*> data_queue;
// 保护消息队列的临界变量
pthread_mutex_t mutex;
// 主线程通知子线程的信号量，可以用pthread_cond_t代替
sem_t sem;

void* thread_func(void*)
{
    while(1)
    {
        sem_wait(&sem);

        pthread_mutex_lock(&mutex);
        if(data_queue.size() > 0)
        {
            // 从队列中得到对象
            DataObject* object = *data_queue.begin();
            data_queue.pop_front();
            pthread_mutex_unlock(&mutex);

            // 对对象进行处理
            printf("%s", object->buf);
            // 释放对象，没有用free，也没有用delete，而是将它放回对象池的free列表
            ObjectPool<DataObject>::freeObject(object);
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
    sem_init(&sem, 0, 0);

    pthread_t thread;
    pthread_create(&thread, NULL, thread_func, NULL);
    while(1)
    {
        // 当需要对象时，从对象池中获取
        DataObject* object = ObjectPool<DataObject>::getObject();
        // 使用对象
        fgets(object->buf, sizeof(object->buf), stdin);

        // 放到队列中，以便子线程能得到这个数据
        pthread_mutex_lock(&mutex);
        data_queue.push_back(object);
        pthread_mutex_unlock(&mutex);

        // 通知子线程
        sem_post(&sem);
    }
    return 0;
}


















