#include "../common.h"
#include <map>

typedef struct user_t 
{
    std::string name;
    std::string ipaddr;
    unsigned short port;
    int fd;
    pthread_t thread;

    int already_named;
} user_t;

// 保存所有的用户信息
std::map<std::string, user_t*> users;
pthread_mutex_t user_mutex;

void remove_user_from_map(user_t* user)
{
    pthread_mutex_lock(&user_mutex);
    users.erase(user->name);
    pthread_mutex_unlock(&user_mutex);
}

void clear_user(user_t* user)
{
    close(user->fd);
    if(user->already_named)
    {
        remove_user_from_map(user);
    }
    delete user;
}

void trans_data(const char* buf, int fd)
{
    unsigned short length = strlen(buf);
    length = htons(length);

    write_data(fd, (const char*)&length, 2);
    write_data(fd, buf, strlen(buf));

}

void response(const user_t* user, const char* cmd, const char* result)
{
    // [长度]setnameack name is null
    char buf[4096];
    sprintf(buf, "%sack %s", cmd, result);

    trans_data(buf, user->fd);
}

void trans_msg(const user_t* userfrom, const user_t* userto, const char* msg)
{
    // recvfrom jack msg
    char buf[4096];
    sprintf(buf, "recvfrom %s %s", userfrom->name.c_str(), msg);

    trans_data(buf, userto->fd);
}

// setname aaa
// list
// send tom hello
void handle_packet(user_t* user, char* buf, int length)
{
    char* saveptr;
    char* cmd = strtok_r(buf, " ", &saveptr);
    // cmd is setname, list, send
    if(strcmp(cmd, "send") == 0)
    {
        if(user->already_named == 0)
        {
            response(user, cmd, "who are you");
            return;
        }

        char* sendto = strtok_r(NULL, " ", &saveptr);   
        if(sendto == NULL)
        {
            response(user, cmd, "which you want send...");
            return;
        }

        char* msg = saveptr;
        printf("msg is %s\n", msg);

        
        user_t* touser = NULL;
        pthread_mutex_lock(&user_mutex);
        auto it = users.find(sendto);
        if(it != users.end())
        {
            touser = it->second;
            trans_msg(user, touser, msg);
        }
        pthread_mutex_unlock(&user_mutex);
        
        // sendto jack aaaaaa
        // recvfrom tom aaaaaa
        return;
    }
    else if(strcmp(cmd, "list") == 0)
    {
        // listack tom jack jarry hello
        std::string buf;
        // tom jack 
        pthread_mutex_lock(&user_mutex);
        for(auto it=users.begin(); 
                it!=users.end(); ++it)
        {
            user_t* u = it->second;
            buf += " ";
            buf += u->name;
        }
        pthread_mutex_unlock(&user_mutex);
       
        // listack  tom jack 
        response(user, cmd, buf.c_str());
        return;

    }
    else if(strcmp(cmd, "setname") == 0)
    {
        if(user->already_named)
        {
            // 说明用户已经有名字了
            response(user, cmd, "you already have name");
            return;

        }

        // 将用户名获取
        char* name = strtok_r(NULL, " ", &saveptr);
        if(name == NULL)
        {
            // 响应客户端
            response(user, cmd, "name is null");
            return;
        }

        pthread_mutex_lock(&user_mutex);
        auto it = users.find(name);
        // 没找到这个用户
        if(it == users.end())
        {
            users.insert(std::pair<std::string, user_t*>(std::string(name), user));
            user->name = name;
            user->already_named = 1;

            response(user, cmd, "ok");

            printf("user %s comming...\n", name);
        }
        else
        {
            response(user, cmd, "user already exist");
        }
        pthread_mutex_unlock(&user_mutex);

        return;
    }
    else
    {
        // 服务器不知道客户端发送的是啥o
        // 干掉这个客户端
    }
}

void* thread_func(void* arg)
{
    user_t* user = (user_t*)arg;
    // 自定义协议中要求有长度
    unsigned short packet_length;

    while(1)
    {
        // 读取报文头长度
        int ret = read_data(user->fd, (char*)&packet_length, 2);
        // packet_length要求是网络序
        packet_length = ntohs(packet_length);
        if(packet_length > 8192)
        {
            clear_user(user);
            break;
        }

        // 可以使用之前的内存池技术
        char* buf = new char[packet_length+1];
        buf[packet_length] = 0; // 保证后面有\0
        ret = read_data(user->fd, buf, packet_length);
        if(ret <= 0)
        {
            clear_user(user);
            break;
        }

        handle_packet(user, buf, packet_length);
        delete []buf;
    }
}


int main(int argc, char* argv[])
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(9989);
    addr.sin_addr.s_addr = 0;

    int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return 0;
    }

    ret = listen(fd, 5);

    pthread_mutex_init(&user_mutex, NULL);

    while(1)
    {
        int fd_connect = accept(fd, NULL, NULL);
        if(fd_connect < 0)
        {
            if(errno == EINTR)
                continue;
            break;
        }

        user_t* user = new user_t;
        user->fd = fd_connect;
        user->already_named = 0;
        pthread_create(&user->thread, NULL, thread_func, user);
    }

    close(fd);

    return 0;
}


















