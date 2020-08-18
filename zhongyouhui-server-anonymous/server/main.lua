local skynet = require "skynet"
require "skynet.manager"
local init_db = require "server.common.init_db"
local hotfix = require "hotfix"
local rpc_mysql = require "rpc_mysql"

skynet.init(function()
    math.randomseed(os.clock() * math.random(1000000, 90000000) + math.random(1000000, 90000000));
end)

skynet.start(function ()
    skynet.uniqueservice("srv_logger_sup")
    skynet.newservice("debug_console", 8903)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end
    
    -- 初始化mysql
    local mysql_config = require("etc." .. skynet.getenv("env") .. ".mysql")
    rpc_mysql.init("zhongyouhui", mysql_config.zhongyouhui)
    init_db()

    -- 启动登陆服务
    local handle = hotfix.start_hotfix_service("skynetunique", "server/service/srv_logon")
    skynet.name(".logon", handle)

    -- 启动俱乐部服务
    local handle = hotfix.start_hotfix_service("skynetunique", "server/service/srv_club")
    skynet.name(".club", handle)

    -- 启动区块链服务
    local handle = hotfix.start_hotfix_service("skynetunique", "server/service/srv_block")
    skynet.name(".block", handle)

    -- 启动杂项服务
    local handle = hotfix.start_hotfix_service("skynetunique", "server/service/srv_misc")
    skynet.name(".misc", handle)

    -- 启动frontend, backend web服务
    local config = require("etc." .. skynet.getenv("env") .. ".server")
    hotfix.start_hotfix_service("skynet", "srv_web", config.backend.port, "server.backend.webapp", 65536)
    hotfix.start_hotfix_service("skynet", "srv_web", config.frontend.port, "server.frontend.webapp", 65536 * 2)

    skynet.exit()
end)
