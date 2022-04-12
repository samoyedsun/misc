docker run -it -d \
    -p 22443:22443 \
    -v ${PWD}/nginx.conf:/usr/local/nginx/conf/nginx.conf \
    --name forwardproxy \
    reiz/nginx_proxy
