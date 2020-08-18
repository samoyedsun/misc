local skynet = require "skynet"
local socketproto = require "socket.proto"
local sproto = require "sproto"
local code = require "server.config.code"
local jproto = require "jproto"
local common_util = require "server.common.common_util"
local http_util = require "server.common.http_util"
local user = require "server.frontend.request.socket_user"
local room = require "server.frontend.request.socket_room"
local game = require "server.frontend.request.socket_game"
local club = require "server.frontend.request.socket_club"
local logger = log4.get_logger("server_frontend_socketproto")

-- local host = sproto.parse(gate_proto.c2s):host "package"
-- local host_request = host:attach(sproto.parse(gate_proto.s2c))
-- proto.configure(host, host_request)

-- 设置客户端消息序列化和反序列化方法
socketproto.configure(jproto.host, jproto.host_request)

socketproto.c2s_before(".*", function (self, name, args, res)
    if (name == "user_auth") or self.session.auth then
        return true
    end
    create_timeout(3 * 100, function(s) self:emit("kick") end)
    table.merge(res, {code = code.ERROR_UNAUTH, err = code.ERROR_UNAUTH_MSG})
    return false
end)

socketproto.c2s_use("^user_*", function (self, name, args, res)
    local expend_time = common_util:create_expend_time()
    table.merge(res, user.request(self, name, args))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, name)
    local ok, text, title = common_util:alarm_format_logic_expend_time("ws", name, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)

socketproto.c2s_use("^room_*", function (self, name, args, res)
    local expend_time = common_util:create_expend_time()
    table.merge(res, room.request(self, name, args))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, name)
    local ok, text, title = common_util:alarm_format_logic_expend_time("ws", name, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)

socketproto.c2s_use("^game_*", function (self, name, args, res)
    local expend_time = common_util:create_expend_time()
    table.merge(res, game.request(self, name, args))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, name)
    local ok, text, title = common_util:alarm_format_logic_expend_time("ws", name, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)

socketproto.c2s_use("^club_*", function (self, name, args, res)
    local expend_time = common_util:create_expend_time()
    table.merge(res, club.request(self, name, args))
    local expend_time = expend_time()
    logger.debug("消耗时间:%s, 协议名:%s", expend_time, name)
    local ok, text, title = common_util:alarm_format_logic_expend_time("ws", name, expend_time)
    if ok then http_util.notify_dingtalk(title, text) end
    return true
end)

socketproto.c2s_after(".*", function (self, name, args, res)
    logger.debug("c2s after %s %s %s %s", "hello", name, tostring(args), "a lot data")
end)

return socketproto
