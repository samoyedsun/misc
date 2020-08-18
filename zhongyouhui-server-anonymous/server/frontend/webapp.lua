local skynet = require "skynet"
local webapp = require "web.app"
local webproto = require "web.proto"
local jproto = require "jproto"
local web_util = require "utils.web_util"
local common_util = require "server.common.common_util"
local http_util = require "server.common.http_util"
local wsapp = require "server.frontend.wsapp"
local game = require "server.frontend.request.web_game"
local gate = require "server.frontend.request.web_gate"
local user = require "server.frontend.request.web_user"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_frontend_webapp")
web_util.set_logger(logger)

local webproto = webproto:new(jproto.host)

webproto:use("error", function ( ... )
    print(...)
    return false
end)

webproto:use(".*", function (req, name, args, res)
    table.merge(res, { test = "is test rpc ", msg = "hello world"})
    return true
end)

webproto:before(".*", web_util.before_log)
webproto:after(".*", web_util.after_log)

--------------------------------------------------------------
webapp.before(".*", function (req, res)
    res.headers["Access-Control-Allow-Origin"] = "*"
    res.headers["Access-Control-Allow-Methods"] = "*"
    res.headers["Access-Control-Allow-Credentials"] = "true"
    return true
end)
webapp.before(".*", function(req, res)
    logger.debug("before web req %s body %s", tostring(req.url), tostring(req.body))
    return true
end)

webapp.use("^/game/:name$",function (req, res)
    local expend_time = common_util:create_expend_time()
    res:json(game.request(req))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, req.path)
    local ok, text, title = common_util:alarm_format_logic_expend_time("http", req.path, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)
webapp.use("^/gate/:name$", function (req, res)
    local expend_time = common_util:create_expend_time()
    res:json(gate.request(req))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, req.path)
    local ok, text, title = common_util:alarm_format_logic_expend_time("http", req.path, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)
webapp.use("^/user/:name$", function (req, res)
    local expend_time = common_util:create_expend_time()
    res:json(user.request(req))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, req.path)
    local ok, text, title = common_util:alarm_format_logic_expend_time("http", req.path, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)

webapp.post("^/jproto$", function ( ... )
    webproto:process(...)
end)
webapp.use("^/ws$", function (...)
    wsapp.process(...)
end)

webapp.after(".*", function(req, res)
    logger.debug("after web req %s body %s res body %s", tostring(req.url), tostring(req.body), tostring(res.body))
    return true
end)

webapp.static("^/static/*", "./server/")

return webapp
