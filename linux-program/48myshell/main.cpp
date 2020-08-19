#include "../common.h"

void print_tip()
{
    printf("myshell$ ");
}

void get_cmd(char* buf, int length)
{
    fgets(buf, length, stdin);
    buf[strlen(buf)-1] = 0;
}

// 将命令分解
int split_cmd(char* buf, char** subs, const char* split)
{
    int count = 0;
    char* sub = strtok(buf, split);

    while(sub)
    {
        subs[count++] = sub;
        sub = strtok(NULL, split);
    }

    return count;
}

// 执行命令,cmd肯定是普通命令
// cmd是即将要处理的普通命令 比如 "ls -al"
// in是标准输入要重定向到该文件描述符
// out 是标准输出要重定向到该文件描述副
// fd 是所有管道文件描述符，只是在子进程中关闭用的----大坑
// fd_count 是管道文件描述符的数量
void exec_sub(char* cmd, int in, int out, int fd[], int fd_count)
{
    // 创建子进程
    pid_t pid = fork();
    if(pid)
    {
        // 设置进程组
        setpgid(pid, pid);
    }
    else if(pid == 0) // 子进程
    {
        // 重定向输入和输出
        if(in != -1)
            dup2(in, 0);
        if(out != -1)
            dup2(out, 1);

        // 很重要：关闭多余的文件描述符（管道）
        for(int i=0; i<fd_count; ++i)
        {
            close(fd[i]);
        }

        // 把类似 ls -al这种普通的命令，使用空格分割开
        char* parts[1024];
        int count = split_cmd(cmd, parts, " ");
        parts[count] = NULL;

        // 调用exec执行
        execvp(parts[0], parts);
        perror("execvp");
        exit(0);
    }
}

int main()
{
    char buf[4096];
    while(1)
    {
        print_tip();
        get_cmd(buf, sizeof(buf));
        if(strlen(buf) == 0)
            continue;

        // 分解命令，通过|符号分解命令
        char* sub_cmds[1024];
        int count = split_cmd(buf, sub_cmds, "|");

        // 没有找到 |，没有重定向， 直接执行
        if(count == 1)
        {
            exec_sub(sub_cmds[0], -1, -1, NULL, 0);
            wait(NULL);
        }
        else
        {
            // 找到了|，说明有重定向
            // 子命令在sub_cmds里，数量是count个
            
            // 创建count-1对管道
            int fd[1024];
            for(int i=0; i<count-1; ++i)
            {
                pipe(&fd[i*2]);
            }

            // 执行count个子命令
            for(int i=0; i<count; ++i)
            {
                if(i == 0)
                    exec_sub(sub_cmds[i], -1, fd[i*2+1], fd, (count-1)*2);
                else if(i == count-1)
                    exec_sub(sub_cmds[i], fd[i*2-2], -1, fd, (count-1)*2);
                else
                    exec_sub(sub_cmds[i], fd[i*2-2], fd[i*2+1], fd, (count-1)*2);
            }

            // 父进程关闭管道
            for(int i=0; i<count-1; ++i)
            {
                close(fd[i*2]);
                close(fd[i*2+1]);
            }

            // 等待所有子进程结束
            for(int i=0;i<count;++i)
            {
                wait(NULL);
            }
        }
    }
}

#if 0
int main(int argc, char* args[])
{
    char buf[4096];
    while(1)
    {
        /* 输出提示符 */
        getcwd(buf, sizeof(buf));
        printf("myshell:%s$ ", buf);

        fgets(buf, sizeof(buf), stdin);
        // 将最后一个\n去掉
        buf[strlen(buf)-1] = 0;
        if(strlen(buf) == 0)
        {
            continue;
        }

        /* 解析命令，并且执行 */
        /* 例如   ls     -al        */

        /* 解析命令 */
        int i = 0;  // 记录命令有多少段
        char* argv[1024];
        char* p = strtok(buf, " ");
        while(p)
        {
            argv[i++] = p;
            p = strtok(NULL, " ");
        }
        argv[i] = NULL;

        // 执行命令
        pid_t pid = fork();

        if(pid == 0)
        {
            execvp(argv[0], argv); 
            perror("execvp");
            // 子进程
            return 0;
        }

        wait(NULL);
    }
    return 0;
}

#endif
















