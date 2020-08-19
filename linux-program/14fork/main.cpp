#include "../common.h"

int add(int a, int b)
{
    return a+b;
}

int sum;

int main()
{
    sum = add(10, 9);
    int*p = (int*)malloc(100);

    int fd = open("a.txt", O_CREAT|O_WRONLY, 0777);

    pid_t pid = fork();

    // fork函数失败了，情况比较少
    if(pid == -1)
    {
        
    }
    
    if(pid > 0)
    {
        write(fd, "hello in parent", 14);
        pid_t self_pid = getpid();
        pid_t parent_pid = getppid();
        // in parent
        printf("[parent]return pid=%d, self_pid=%d, parent_pid=%d\n", (int)pid, (int)self_pid, (int)parent_pid);
        sleep(1);
    }
    else if(pid == 0)
    {
        write(fd, "hello in child", 14);
        pid_t self_pid = getpid();
        pid_t parent_pid = getppid();
        printf("sum is %d\n", sum); // sum is 19
        // in child
        printf("[child]return pid=%d, self_pid=%d, parent_pid=%d\n", (int)pid, (int)self_pid, (int)parent_pid);
    }

    free(p);
    close(fd);

    return 0;
}
