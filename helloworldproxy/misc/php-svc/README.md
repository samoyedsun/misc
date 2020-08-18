# web

- 使用方法
```shell
    git clone https://github.com/TD1900/web.git
    docker run --name web -v $PWD/web/.90aA_p/nginx.conf:/etc/nginx/nginx.conf:ro -v $PWD/web/:/root/web/ -d -p 80:80 nginx nginx-debug -g 'daemon off;'
```
