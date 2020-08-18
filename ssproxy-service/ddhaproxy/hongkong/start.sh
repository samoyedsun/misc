SUFFIX=prod
docker run -d -p 28912:8388 -v $PWD/haproxy.cfg.${SUFFIX}:/usr/local/etc/haproxy/haproxy.cfg:ro --name haproxy-${SUFFIX} haproxy
SUFFIX=test
docker run -d -p 28913:8388 -v $PWD/haproxy.cfg.${SUFFIX}:/usr/local/etc/haproxy/haproxy.cfg:ro --name haproxy-${SUFFIX} haproxy

docker run -d -p 28911:28911 --name ssproxy-obfs samoyedsun/ssproxy-obfs
