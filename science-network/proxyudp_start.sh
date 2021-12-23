docker run -it -d -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf:ro -p 80:80 -p 500:500/udp -p 4500:4500/udp --name proxyudp nginx
