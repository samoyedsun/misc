local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local logger = log4.get_logger("server_common_common_db")

local root = {}
function root:create_mysql_connect()
	local function on_connect(db)
        db:query("set charset utf8");
    end
    local env = skynet.getenv("env")
    local mysql_config = table.copy(require("etc." .. env .. ".mysql")["zhongyouhui"])
    mysql_config.on_connect = on_connect
    return mysql.connect(mysql_config)
end

function root:query_by_mysql_connect(db, command)
    logger.debug("query mysql command:%s", command)
    return db:query(command)
end

function root:close_mysql_connect(db)
    db:disconnect()
end

function root:single_use_mysql_connect(command)
	local function on_connect(db)
        db:query("set charset utf8");
    end
    local env = skynet.getenv("env")
    local mysql_config = table.copy(require("etc." .. env .. ".mysql")["zhongyouhui"])
    mysql_config.on_connect = on_connect
    local db = mysql.connect(mysql_config)
    local res = db:query(command)
    db:disconnect()
    return res
end

return root