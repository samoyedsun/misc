#include "../common.h"

struct data_node
{
    struct data_node* next;
    int value;
};

struct data_node* head = NULL; 

pthread_mutex_t mutex;
pthread_cond_t cond;

// 生产者
void* thread1_func(void*)
{
    while(1)
    {
       sleep(1); 

       struct data_node* node = (struct data_node*)malloc(sizeof(*node));
       node->value = rand();

       pthread_mutex_lock(&mutex);
       node->next = head;
       head = node;
       pthread_mutex_unlock(&mutex);

       pthread_cond_signal(&cond);
    }
}

void* thread2_func(void*)
{
    while(1)
    {
        sleep(5);

        pthread_mutex_lock(&mutex);
        while(head == NULL)
        {
            pthread_cond_wait(&cond, &mutex);
         //   unlock(mutex);
         //   wait();
         //   lock(mutex);
        }

        struct data_node* node = head;
        head = head->next;
        pthread_mutex_unlock(&mutex);

        printf("%d\n", node->value);
        free(node);
    }
}

int main(int argc, char* argv[])
{
    srand(time(NULL));
    pthread_mutex_init(&mutex, NULL);
    pthread_cond_init(&cond, NULL);

    pthread_t p1;
    pthread_t p2;
    pthread_create(&p1, NULL, thread1_func, NULL);
    pthread_create(&p2, NULL, thread2_func, NULL);

    pthread_join(p1, NULL);
    pthread_join(p2, NULL);
    return 0;
}


















