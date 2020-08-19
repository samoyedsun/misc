#include "../common.h"
#include <sys/socket.h>
#include <netpacket/packet.h>
#include <net/ethernet.h>
#include <sys/ioctl.h>
#include <linux/if.h>

/* 物理网卡混杂模式属性操作 */
static int ethdump_setPromisc(const char *pcIfName, int fd, int iFlags)
{
    int iRet = -1;
    struct ifreq stIfr;
    /* 获取接口属性标志位 */
    strcpy(stIfr.ifr_name, pcIfName);
    iRet = ioctl(fd, SIOCGIFFLAGS, &stIfr);
    if (0 > iRet)
    {
        perror("[Error]Get Interface Flags");    
        return -1;
    }

    if (0 == iFlags)
    {
        /* 取消混杂模式 */
        stIfr.ifr_flags &= ~IFF_PROMISC;
    }
    else
    {
        /* 设置为混杂模式 */
        stIfr.ifr_flags |= IFF_PROMISC;
    }
    iRet = ioctl(fd, SIOCSIFFLAGS, &stIfr);
    if (0 > iRet)
    {
        perror("[Error]Set Interface Flags");
        return -1;
    }

    return 0;
}


#pragma pack(1)
struct eth_frame
{
    unsigned char dst[6];
    unsigned char src[6];
    unsigned short type;
    char data[];
};

struct ip_dgram
{
    uint8_t type: 4; // IPV4 or IPV6
    uint8_t length: 4;  // 以四个字节单位
    uint8_t tos;
    uint16_t total_length;
    uint16_t flag;
    uint16_t sig: 3;
    uint16_t offset:13;
    uint8_t ttl;
    uint8_t protocal;  // TCP or UDP
    uint16_t crc;
    uint32_t src_ip; // 32位
    uint32_t dst_ip;
    char data[];
};

struct tcp_packet
{
    uint16_t src_port;
    uint16_t dst_port;
    uint32_t seq;
    uint32_t seq_ack;
    uint32_t length:4;    
    uint32_t r:6;
    uint32_t flag:6;
    uint32_t win_size:16;
    uint16_t crc;
    uint16_t sos;
};
#pragma pack()

int main(int argc, char* argv[])
{
    // 原始套接字 
    int sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));

    int ok1 = ethdump_setPromisc("eth0", sock, 1);
    int ok2 = ethdump_setPromisc("eth1", sock, 1);
    printf("ok1=%d, ok2=%d\n", ok1, ok2);

    char buf[2048];
    while(1)
    {
        int ret = recv(sock, buf, sizeof(buf), 0);
        if(ret <= 0)
            continue;

        struct eth_frame* frame = (struct eth_frame*)buf;
        struct ip_dgram* ip = (struct ip_dgram*)frame->data;
        int ip_head_length = ip->length * 4;

        struct tcp_packet* tcp = (struct tcp_packet*)(frame->data + ip_head_length);
        int tcp_head_length = tcp->length * 4;

        char* tcp_data = frame->data + ip_head_length + tcp_head_length;

        // ip->type == 5 表示UDP
        if(ntohs(frame->type) == 0x0800 && ip->protocal != 17)
        {

#if 0
            printf("dst is %02x:%02x:%02x:%02x:%02x:%02x\n", 
                    frame->dst[0], 
                    frame->dst[1], 
                    frame->dst[2], 
                    frame->dst[3], 
                    frame->dst[4], 
                    frame->dst[5]);

            printf("src is %02x:%02x:%02x:%02x:%02x:%02x\n", 
                    frame->src[0], 
                    frame->src[1], 
                    frame->src[2], 
                    frame->src[3], 
                    frame->src[4], 
                    frame->src[5]);
#endif
            //   printf("type is %04x\n", ntohs(frame->type));


#if 0
            struct sockaddr_in addr;
            addr.sin_addr.s_addr = ip->src_ip;
            char* src_ip = strdup(inet_ntoa(addr.sin_addr));
            addr.sin_addr.s_addr = ip->dst_ip;
            char* dst_ip = strdup(inet_ntoa(addr.sin_addr));

            printf("from %s to %s, protocal is %d\n", src_ip, dst_ip, (int)ip->protocal);

            free(src_ip);
            free(dst_ip);
#endif

            printf("tcp is: %s\n", tcp_data);
        }
    }

    return 0;
}


















