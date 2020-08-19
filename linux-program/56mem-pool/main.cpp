#include "../common.h"
#include <map>
using namespace std;

// void* mymalloc(int size);
// void myfree(void* p);

// #define mymalloc malloc
// #define myfree free

// 需要记录你申请的地址和申请位置的文件名和行号的关系
struct mem_alloc_pos_t
{
    const char* filename;
    int line;

    mem_alloc_pos_t(const char* filename, int line):filename(filename), line(line)
    {
    
    }
};

    
struct mem_node_t
{
    char head[8]; // head[0];
    struct mem_node_t* next;
};

struct mem_pool_t
{
    // 16 ~ 4096
    // p[0] 4096长度的空闲内存
    // p[1] 2048长度的空闲内存
    // .... 链表
    struct mem_node_t* head[9]; 

    char** mem_trunk; // 一个trunk是4096
    int trunk_count; // 记录当前有多少trunk
    int trunk_max_count; //

    std::map<char*,  mem_alloc_pos_t*> pos;
    pthread_mutex_t mutex;

};
void mem_pool_set_alloc_info(mem_pool_t* pool, char* p, const char* filename, int line)
{
    mem_alloc_pos_t* pos = new mem_alloc_pos_t(filename, line);
    pool->pos.insert(pair<char*, mem_alloc_pos_t*>(p, pos));
}

static int block_size[] = {
    4096,
    2048,
    1024,
    512,
    256,
    128,
    64,
    32,
    16
};

// 16 * (1 << (8-idx));
// 0 -> 4096
// 1 -> 2048
// 2 -> 1024
// 3 -> 512
//

void mem_pool_add_trunk(struct mem_pool_t* pool, char* trunk)
{
    if(pool->trunk_count == pool->trunk_max_count)
    {
        // 申请空间
        pool->mem_trunk = (char**)realloc(pool->mem_trunk, sizeof(char*)*(pool->trunk_max_count*2));
        pool->trunk_max_count *= 2;
    }
    //
    pool->mem_trunk[pool->trunk_count++] = trunk;

}

void mem_pool_init(struct mem_pool_t* pool)
{
    pool->trunk_count = 0;
    pool->mem_trunk = (char**)malloc(sizeof(char*)*1024);
    pool->trunk_max_count = 1024;
    pthread_mutex_init(&pool->mutex, NULL);

    for(int i=0; i<9; ++i)
    {
        pool->head[i] = NULL;
    }
}

void mem_pool_check(struct mem_pool_t* pool)
{
    printf("mem trunk count is %d\n", pool->trunk_count);
    for(int i=0;i <pool->trunk_count; ++i)
    {
        char* trunk = pool->mem_trunk[i]; 
        int offset = 0;
        while(1)
        {
            char head = trunk[offset];

            int idx = head & 0x0f;
            int freeflag = head & 0xf0;
            freeflag >>= 4;

            if(freeflag == 1)
            {
                mem_alloc_pos_t* pos = pool->pos[trunk+offset];
                printf("mem leak: %s, %d\n", pos->filename, pos->line);
            }

            printf("idx is %d, freeflag is %d, offset is %d\n", idx,freeflag,  offset);
            offset += block_size[idx];
            if(offset >= 4096)
                break;
        }
    } 
}

void* mymalloc(int size, struct mem_pool_t* pool, const char* filename, int line);

void* mymalloc_lock(int size, struct mem_pool_t* pool, const char* filename, int line)
{
    pthread_mutex_lock(&pool->mutex);
    mymalloc(size, pool, filename, line);
    pthread_mutex_unlock(&pool->mutex);
}
void* mymalloc(int size, struct mem_pool_t* pool, const char* filename, int line)
{
    int idx;
    size = size+1;
    // get_index(
    // 这个代码太挫，今天晚上你们优化
    if(size <= 16)
    {
        idx = 8;
    }
    else if(size <= 32)
    {
        idx = 7;
    }
    else if(size <= 64)
    {
        idx = 6;
    }
    else if(size <= 128)
    {
        idx = 5;
    }
    else if(size <= 256)
    {
        idx = 4;
    }
    else if(size <= 512)
    {
        idx = 3;
    }
    else if(size <= 1024)
    {
        idx = 2;
    }
    else if(size <= 2048)
    {
        idx = 1;
    }
    else if(size <= 4096)
    {
        idx = 0;
    }
    else
    {
        char* p = (char*)malloc(size);
        p[0] = 0x09;
        return p+1;
    }

    int find_idx = idx;
    struct mem_node_t* head;
    while(1)
    {
        head = pool->head[find_idx];
        if(head)
            break;
        find_idx --;
        if(find_idx == -1)
        {
            // 申请4096内存，放到pool->head[0]位置，find_idx = 0;
            //  void* p = malloc(4096); // 可以用mmap代替
            struct mem_node_t* p = (struct mem_node_t*)mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANON, -1, 0);
            mem_pool_add_trunk(pool, (char*)p);

            // 把链表插入4096空闲内存的链表头
            p->next = pool->head[0];
            pool->head[0] = p;
            find_idx = 0;
            break;
        }
    }

    // find_idx肯定找到了
    char* p = (char*)pool->head[find_idx];
    // 删除头节点
    pool->head[find_idx] = pool->head[find_idx]->next;

    if(find_idx != idx)
    {
        while(1)
        {
            int find_block_size = block_size[find_idx];
            char* half1 = p;
            char* half2 = p+find_block_size/2;
            find_idx ++;

            struct mem_node_t* node = (struct mem_node_t*)half2;
            node->head[0] = find_idx;
            node->next = pool->head[find_idx];
            pool->head[find_idx] = node;

            p = half1;
            if(find_idx == idx)
                break;
        }
    }

    p[0] = idx | 0x10;
    mem_pool_set_alloc_info(pool, p, filename, line);
    return p+1;

#if 0
    if(find_idx == idx)
        return p;
    else
    {
        while(1)
        {
            int find_block_size = block_size[find_idx];
            char* half1 = p;
            char* half2 = p + find_block_size/2;

            struct mem_node_t* node = (struct mem_node_t*)half2;

            node->next = pool->head[find_idx+1];
            pool->head[find_idx+1] = node;
            if(find_idx == idx)
                return half1;
        }
    }
#endif
}

void myfree(void* ptr, struct mem_pool_t* pool)
{
    pthread_mutex_lock(&pool->mutex);
    char* p = (char*)ptr;
    p --; 
    char idx = p[0] & 0x0f;

    if(idx == 0x09)
        free(p);
    else
    {
        struct mem_node_t* node = (struct mem_node_t*)p;
        node->next = pool->head[idx];
        pool->head[idx] = node;
        node->head[0] = idx;

        delete pool->pos[p];
        pool->pos.erase(p);
    }
    pthread_mutex_unlock(&pool->mutex);
}

struct mem_pool_t global_pool;
#define mymalloc2(size) mymalloc_lock(size, &global_pool, __FILE__, __LINE__)
#define myfree2(ptr) myfree(ptr, &global_pool)

int main(int argc, char* argv[])
{

    mem_pool_init(&global_pool);

    char* p = (char*)mymalloc2(438);
    printf("%d\n", (int)*(p-1));

    myfree2(p);

    p = (char*)mymalloc2(15);
    mem_pool_check(&global_pool);

    return 0;
}


















