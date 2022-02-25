#ifndef _MEM_POOL_H_
#define _MEM_POOL_H_

#include <iostream>
#include <map>

using namespace std;

class mem_pool
{
        struct alloc_pos_t
        {
            const char *m_filename;
            int m_line;

            alloc_pos_t(const char *filename, int line)
                :m_filename(filename), m_line(line)
            {
            }
        };

        struct mem_node_t
        {
            char m_head_idx;
            struct mem_node_t *m_next;
        };

    public:
        void init();
        void *mymalloc(int size, const char *filename, int line);
        void myfree(void *ptr);
        void check();
        
    private:
        void add_trunk(char *trunk);

    private:
        struct mem_node_t *m_head[9];

        char **m_mem_trunk;
        int m_trunk_count;
        int m_trunk_max_count;

        map<char *, struct alloc_pos_t *> m_pos_map;
        pthread_mutex_t m_mutex;

    public:
        static const int MEM_POOL_DEFAULT_SIZE = 1024;
};

extern mem_pool g_com_mem_pool;
extern mem_pool g_net_mem_pool;

#define NETMEMINIT() g_net_mem_pool.init()
#define NETMEMMALLOC(size) g_net_mem_pool.mymalloc(size, __FILE__, __LINE__)
#define NETMEMFREE(ptr) g_net_mem_pool.myfree(ptr)
#define NETMEMCHECK() g_net_mem_pool.check()

template<typename T>
T* construct_from_pool()
{
    void *p = g_com_mem_pool.mymalloc(sizeof(T), __FILE__, __LINE__);
    if (!p)
    {
        return NULL;
    }
    return new (p) T();
}

template<typename T>
void destroy_to_pool(T* p)
{
    p->destroy();
    p->~T();
    g_com_mem_pool.myfree(p);
}

#endif