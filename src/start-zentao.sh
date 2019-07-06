docker run -d -p 801:80 -p 3306:3306 \
        -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
        -e BIND_ADDRESS="false" \
        -v /data/zbox/:/opt/zbox/ \
        --add-host smtp.exmail.qq.com:163.177.90.125 \
        --name zentao-server \
        idoop/zentao:latest
