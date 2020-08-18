PREFIX=haproxy
PORT=28911
docker stop ${PREFIX}${PORT}
docker rm ${PREFIX}${PORT}
PORT=28912
docker stop ${PREFIX}${PORT}
docker rm ${PREFIX}${PORT}
PORT=28913
docker stop ${PREFIX}${PORT}
docker rm ${PREFIX}${PORT}
