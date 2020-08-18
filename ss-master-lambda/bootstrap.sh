#!/bin/bash
# 环境: aliyun ecs
# 系统: ubuntu 18.04
#echo "sleep 300 begin."
#sleep 300
#echo "sleep 300 end."
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
# 启动代理容器
docker run -it -d -p 13003:13003 --name ssproxy samoyedsun/ssproxy