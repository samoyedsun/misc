#!/bin/bash

# 启动socket5代理服务
docker run \
    --rm \
    -d \
    -p 13003:13003 \
    -e SS_PASS=helloworld \
    -e SS_MODE=rc4-md5 \
    --name ssproxy-base samoyedsun/ssproxy

# 启动socket5免密服务
docker run \
    --rm \
    -d \
    -p 13002:13002 \
    --link ssproxy-base:host-ssproxy-base \
    --name ssproxy-socket5 samoyedsun/ssproxy \
    ss-local -s host-ssproxy-base -p 13003 -k helloworld -m rc4-md5 -b 0.0.0.0 -l 13002

# socket5转http/https
docker run \
    --rm \
    -d \
    -p 13001:13001 \
    --link ssproxy-socket5:host-ssproxy-socket5 \
    -v $PWD/config:/root/config \
    --privileged=true \
    --name ssproxy-httpors samoyedsun/ssproxy \
    privoxy --no-daemon config
