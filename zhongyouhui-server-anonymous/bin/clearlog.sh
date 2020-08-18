#!/bin/sh
find /root/zhongyouhui-server/logs/ -mtime +7 -name "*.log" -exec rm -rf {} \;