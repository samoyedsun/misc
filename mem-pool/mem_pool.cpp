#include "mem_pool.h"
#include <iostream>
#include <map>

using namespace std;

static const int BLOCK_SIZE_LIST[] = 
{
    0x10 << 8,
    0x10 << 7,
    0x10 << 6,
    0x10 << 5,
    0x10 << 4,
    0x10 << 3,
    0x10 << 2,
    0x10 << 1,
    0x10 << 0,
};

void mem_pool::init()
{
    m_trunk_count = 0;
    m_mem_trunk = (char **)malloc(sizeof(char *) * MEM_POOL_DEFAULT_SIZE);
    m_trunk_max_count = MEM_POOL_DEFAULT_SIZE;
    pthread_mutex_init(&m_mutex, NULL);

    for (int i = 0; i <= 8; ++i)
        m_head[i] = NULL;
}


void *mem_pool::mymalloc(int size, const char *filename, int line)
{
    pthread_mutex_lock(&m_mutex);

    int idx = sizeof(BLOCK_SIZE_LIST) / sizeof(int) - 1;
    for (; idx >= 0; --idx)
        if (size <= BLOCK_SIZE_LIST[idx])
            break;
    if (idx < 0)
    {
        char *p = (char *)malloc(size);
        p[0] = 0x09;
        return p + 1;
    }

    int find_idx = idx;
    while(true)
    {
        if (m_head[find_idx])
            break;
        if (find_idx == 0)
        {
            struct mem_node_t *node_ptr = (struct mem_node_t *)malloc(4096);
            add_trunk((char *)node_ptr);
            
            node_ptr->m_next = m_head[find_idx];
            m_head[find_idx] = node_ptr;
            break;
        }
        --find_idx;
    }

    char *p = (char *)m_head[find_idx];
    m_head[find_idx] = m_head[find_idx]->m_next;

    if (find_idx != idx)
    {
        while (true)
        {
            char *half = p + BLOCK_SIZE_LIST[find_idx] / 2 ;
            ++find_idx;
            
            struct mem_node_t *node_ptr = (struct mem_node_t *)half;        
            node_ptr->m_head_idx = find_idx;
            node_ptr->m_next = m_head[find_idx];
            m_head[find_idx] = node_ptr;

            if (find_idx == idx)
                break;
        }
    }

    p[0] = idx | 0x10;
    m_pos_map.insert(pair<char *, alloc_pos_t *>(p, new alloc_pos_t(filename, line)));

    pthread_mutex_unlock(&m_mutex);
    return p + 1;
}

void mem_pool::myfree(void *ptr)
{
    pthread_mutex_lock(&m_mutex);
    char *p = (char *)ptr;
    --p;
    char idx = p[0] & 0x0f;
    if (idx == 0x09)
        free(p);
    else
    {
        struct mem_node_t *node_ptr = (struct mem_node_t *)p;
        node_ptr->m_head_idx = idx;
        node_ptr->m_next = m_head[idx];
        m_head[idx] = node_ptr;

        delete m_pos_map[p];
        m_pos_map.erase(p);
    }
    pthread_mutex_unlock(&m_mutex);
}

void mem_pool::check()
{
    cout << "trunk_count:" << m_trunk_count << endl;
    cout << "trunk_max_count:" << m_trunk_max_count << endl;
    for (int i = 0; i < 9; ++i)
        if (m_head[i] != NULL)
            cout << i << "head:" << m_head[i] << endl;
    for (int i = 0; i < m_trunk_count; ++i)
    {
        char *trunk = m_mem_trunk[i];
        int offset = 0;
        while (true)
        {
            char head = trunk[offset];

            int idx = head & 0x0f;
            int free_flag = head & 0xf0;
            free_flag >>= 4;
                
            if (free_flag == 1)
            {
                alloc_pos_t *pos = m_pos_map[trunk + offset];
                cout << "memory leak:" << pos->m_filename << ", " << pos->m_line << endl;
            }
            offset += BLOCK_SIZE_LIST[idx];
            if (offset >= 4096)
                break;
        }
    }
}

void mem_pool::add_trunk(char *trunk)
{
    if (m_trunk_count == m_trunk_max_count)
    {
        m_mem_trunk = (char **)realloc(m_mem_trunk, sizeof(char *) * (m_trunk_max_count * 2));
        m_trunk_max_count *= 2;
    }
    m_mem_trunk[m_trunk_count++] = trunk;
}

mem_pool g_com_mem_pool;
mem_pool g_net_mem_pool;