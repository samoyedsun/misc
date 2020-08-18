SUFFIX=prod
docker stop haproxy-${SUFFIX}
docker rm haproxy-${SUFFIX}
SUFFIX=test
docker stop haproxy-${SUFFIX}
docker rm haproxy-${SUFFIX}

docker stop ssproxy-obfs
docker rm ssproxy-obfs
