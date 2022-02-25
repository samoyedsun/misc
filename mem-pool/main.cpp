#include "mem_pool.h"

int main(int argc, char *argv[])
{
    NETMEMINIT();

    char *ptr = NULL;
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);
    ptr = (char *)NETMEMMALLOC(512);
    NETMEMFREE(ptr);

    /*
    ptr = (char *)MEMMALLOC(512);
    ptr = (char *)MEMMALLOC(512);
    ptr = (char *)MEMMALLOC(512);
    ptr = (char *)MEMMALLOC(512);
    ptr = (char *)MEMMALLOC(512);
    ptr = (char *)MEMMALLOC(512);
    */

    NETMEMCHECK();

    return 0;
}

