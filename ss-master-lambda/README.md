# ss-master-lambda
阿里云函数计算实践

安装依赖
```bash
pip install aliyun-python-sdk-core
pip install aliyun-python-sdk-ecs
```

add to /etc/crontab
```crontab
0 7 * * * root cd /root/data-collection-devops && bash start.sh CRON=1
```

启动
```bash
cron -n
```
