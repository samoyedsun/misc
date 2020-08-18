作者信息
---
- 作者:LGC
- 时间:2017年 3月 4日 星期六 10时44分20秒 

- 作者:MRZ
- 时间:2019年 6月18日 星期二 17时28分40秒

学习资料
---
|标题|网址| |-|-|
|服务端框架skynet|https://github.com/cloudwu/skynet/wiki|
|skynet学习资源|http://skynetclub.github.io/skynet/resource.html|
|云风的演讲视频|http://gad.qq.com/content/coursedetail?id=467|
|云风的blog|https://blog.codingnow.com/|

本框架解决了以下问题
---
- 服务器热更新
- log4日志服务功能
- web服务功能
- 服务注册与发现功能
- 基于http协议，消息序列化和反序列化基于json的rpc功能
- mysql和redis代理功能
- websocket

集成库
---
- cjson
- lfs
- websocket

目录说明
```txt
.
├── README.md
├── bin                     skynet启动shell脚本
├── cloud                   游戏基础框架
├── etc                     skynet进程启动配置文件
├── logs                    日志目录
├── run                     进程运行时存放文件目录，比如说进程pid
├── server                  多进程不同进程逻辑的服务
└── test                    测试代码目录

./server/
├── backend                 后端请求
├── common                  公共代码
├── config                  游戏配置
├── frontend                前端请求
├── lualib                  lua模块代码
├── main.lua                启动main
├── service                 skynet服务目录
└── static                  http静态文件下载
```

编译前:
- macosx
    ```sh
    brew install openssl
    ```
- ubuntu
    ```sh
    sudo apt install libcurl4-gnutls-dev libreadline-dev autoconf libssl-dev
    ```
- centos
    ```sh
    sudo yum install libcurl-devel readline-devel autoconf openssl-devel
    ```

编译:
---
- Linux
    ```sh
    git submodule update --init  && cd cloud && make linux && cd ..
    ```
- Mac
    ```sh
    git submodule update --init  && cd cloud && make macosx && cd ..
    ```
- 启动命令:
    ```sh
    ./bin/start.sh -v dev
    ./bin/start.sh -v test
    ./bin/start.sh -v prod
    ```
- 后台运行:
    ```sh
    ./bin/start.sh -v dev -D
    ./bin/start.sh -v test -D
    ./bin/start.sh -v prod -D
    ```
- 热更新命令:
    ```sh
    ./bin/start.sh -U
    ```
- 停止运营
    ```sh
    curl -H "Content-Type:application/json" -X POST --data '{}' http://localhost:8103/room/stop_operations
    ```
- 开启运营
    ```sh
    curl -H "Content-Type:application/json" -X POST --data '{}' http://localhost:8103/room/open_operations
    ```

- 日志清理
    ```sh
    CLEARLOGCRONPATH=/etc/cron.d/clearskynetlog
    echo "SHELL=/bin/sh" > ${CLEARLOGCRONPATH}
    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> ${CLEARLOGCRONPATH}
    echo "30 6 * * * root sh /root/zhongyouhui-server/bin/clearlog.sh" >> ${CLEARLOGCRONPATH}
    ```

常见问答A&Q：
- MAC下编译如果遇到的问题:
    - 以下报错
        ```txt
        ld: library not found for -lgcc_s.10.4
        ```
    - 需要做以下操作解决
        ```sh
        cd /usr/local/lib && sudo ln -s ../../lib/libSystem.B.dylib libgcc_s.10.4.dylib
        ```
    - 解决方法来自[这里](http://bugsfixes.blogspot.com/2016/02/mac-ld-library-not-found-for-lgccs104.html)


Anonymous:
- modified:   server/frontend/request/socket_room.lua
- modified:   server/frontend/request/web_game.lua
- modified:   server/lualib/logon_helper.lua
- modified:   server/lualib/room.lua
- modified:   server/lualib/room_helper.lua
- modified:   server/lualib/state_machine.lua
- deleted:    server/static/GfZuZiKATC0OlJsoWoIvxhkfPrvP0MBz.html
- deleted:    server/static/js/logic.js
- deleted:    server/static/js/socket.js
