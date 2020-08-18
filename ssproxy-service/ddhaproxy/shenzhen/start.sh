PREFIX=haproxy
PORT=28911
docker run -d -p ${PORT}:8388 -v $PWD/${PREFIX}${PORT}.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro --name ${PREFIX}${PORT} haproxy
PORT=28912
docker run -d -p ${PORT}:8388 -v $PWD/${PREFIX}${PORT}.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro --name ${PREFIX}${PORT} haproxy
PORT=28913
docker run -d -p ${PORT}:8388 -v $PWD/${PREFIX}${PORT}.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro --name ${PREFIX}${PORT} haproxy
