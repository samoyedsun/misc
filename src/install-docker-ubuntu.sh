#!/bin/bash

# 环境: aliyun ecs
# 系统: ubuntu 18.04

# 清理旧的docker
apt remove docker docker-engine docker.io -y

# 更新apt软件包索引
apt update -y

# 安装软件包,以允许apt通过https使用镜像仓库
apt install \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common \
     -y

# 添加docker官方的GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 验证指纹是否为 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88
apt-key fingerprint 0EBFCD88

# 设置stable镜像仓库
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

# 更新apt软件包索引
apt update -y

# 安装最新版本的docker ce
apt install docker-ce -y
