docker run -it -d \
    -p 22443:22443 \
    -v ${PWD}/nginx.conf:/usr/local/nginx/conf/nginx.conf \
    --name forward-proxy \
    reiz/nginx_proxy
docker run -it -d \
    -p 15135:15135 \
    -p 15129:15129 \
    -v ${PWD}/nginx-ftp.conf:/etc/nginx/nginx.conf \
    --name forward-ftp-proxy \
    nginx
