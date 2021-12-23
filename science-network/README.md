# ssproxy-service
基于docker的ss代理服务

- 支持socket5代理
- 支持socket5免密代理
- 支持socket5转http/https

# 使用方式:
```shell
INSTANCE_IP=x.x.x.x
export http_proxy=http://${INSTANCE_IP}:13001;export https_proxy=http://${INSTANCE_IP}:13001;
```

# 实现中继转发或高可用负载均衡:
```shell
wget https://gist.githubusercontent.com/samoyedsun/735ebb84ce7dfa42ce7e598ec469277d/raw/37a6a1d50635c0884a612b4c811e22794f615171/haproxy.cfg
docker run -d -p 2020:2018 -p 8890:8888 -v $PWD/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro --name haproxy_to_ssproxy haproxy
```

#### [VPN客户端使用资料](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md)
