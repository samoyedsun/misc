#include "../common.h"

int main(int argc, char* argv[])
{
    char buf[1024];
    unsigned short length ;
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(9989);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    int ret = connect(fd, (struct sockaddr*)&addr, sizeof(addr));

    pid_t pid = fork();
    if(pid == 0)
    {
        while(1)
        {
            read_data(fd, (char*)&length, 2);
            length = ntohs(length);

            memset(buf, 0, sizeof(buf));
            read_data(fd, buf, length);
            // listack
            // setnameack
            // sendack
            printf("%s\n", buf);

        }
        return 0;
    }

    while(1)
    {
        // setname xxx
        fgets(buf, sizeof(buf), stdin);

        if(strncmp(buf, "to", 2) == 0)
        {
            // to bbb
            strtok(buf, " ");
            char* touser = strdup(strtok(NULL, " "));
            while(1)
            {
                fgets(buf, sizeof(buf), stdin);
                // 发送命令给服务器
                char msg[2048];
                sprintf(msg, "send %s %s", touser, buf); 
                length = strlen(buf);
                length-=1; // \n不要发
                length = htons(length); // 长度转换成网络序

                write_data(fd, (const char*)&length, 2);
                write_data(fd, buf, strlen(buf)-1); // 内容的长度-1，表示把\n去掉

            }
        }

        length = strlen(buf);
        length-=1; // \n不要发
        length = htons(length); // 长度转换成网络序

        write_data(fd, (const char*)&length, 2);
        write_data(fd, buf, strlen(buf)-1); // 内容的长度-1，表示把\n去掉
    }

    close(fd);

    return 0;
}


















