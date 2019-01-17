#!/bin/bash

# 环境: aliyun ecs
# 系统: ubuntu 18.04

# 创建一个叫做SOCKS的链
iptables -t nat -N SOCKS

# 忽略本地地址
iptables -t nat -A SOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A SOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A SOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A SOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A SOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A SOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A SOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A SOCKS -d 240.0.0.0/4 -j RETURN

# 除了上面的所有流量都跳转到SOCKS本地端口,这里使用shadowsock的默认端口1080
iptables -t nat -A SOCKS -p tcp -j REDIRECT --to-ports 1080

# 最后是应用上面的规则，将OUTPUT出去的tcp流量全部经过SOCKS链
iptables -t nat -A OUTPUT -p tcp -j SOCKS
