#!/bin/bash

# 环境: aliyun ecs
# 系统: ubuntu 18.04

echo "sleep 100 begin."
sleep 300
echo "sleep 100 end."

# 更新apt软件包索引
apt update -y

# 更新apt软件包
apt list --upgradable

# 安装docker服务
apt install docker.io -y

# 启动docker服务
systemctl start docker

# 设置开机自启动
systemctl enable docker

# 启动proxy container
docker run -it \
    -d \
    --rm \
    -p 12000:13003 \
    -e SS_PASS=helloworld12000 \
    -e SS_MODE=aes-256-cfb \
    --name ssproxy samoyedsun/ssproxy
