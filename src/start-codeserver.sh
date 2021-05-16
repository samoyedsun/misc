docker run -d \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Asia/Shanghai \
    -e PASSWORD=password `#optional` \
    -e HASHED_PASSWORD= `#optional` \
    -e SUDO_PASSWORD=password `#optional` \
    -e SUDO_PASSWORD_HASH= `#optional` \
    -e PROXY_DOMAIN=code-server.my.domain `#optional` \
    -p 8443:8443 \
    -p 27011:27013 \
    -p 7011:7012 \
    -v ${PWD}/codeserver:/config \
    --restart unless-stopped \
    --name codeserver \
    ghcr.io/linuxserver/code-server
