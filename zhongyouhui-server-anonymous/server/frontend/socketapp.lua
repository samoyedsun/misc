local skynet = require "skynet"
local socketapp = require "socket.app"
local socketproto = require "server.frontend.socketproto"
local code = require "server.config.code"
local session_class = require "server.lualib.session"
local logger = log4.get_logger("server_frontend_socketapp")

socketapp.use("^c2s$", socketproto.c2s_process)
socketapp.use("^s2c$", socketproto.s2c_process)

socketapp.use("^error$", function (self, _name, _type, ...)
    if _type == "c2s" then
        logger.error("%s %s %s", _type, self.session:tostring(), tostring({...}))
        local name, args, res, err = ...
        if res and type(res) == "table" then
            table.merge(res, {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG})
        end
        return true
    end
    if _type == "socket" and not self.session then
        logger.debug("%s %s", _type, tostring({...}))
        return true
    end

    logger.error("%s %s %s", _type, self.session:tostring(), tostring({...}))
    if _type == "s2c" then
    elseif _type == "proto" then
    elseif _type == "emit" then
    end
    return true
end)

socketapp.use("^start$", function (self, _name, options)
    self.session = session_class:new(options)
    logger.debug("start session:%s", self.session:tostring())
    --[[
    skynet.fork(function ( ... )
        while self.session do
            -- self:emit("s2c", "on_user_heartbeat")                        -- TODO: 发送心跳
            skynet.sleep(1000)
        end
    end)
    --]]
end)

socketapp.use("^close$", function (self)
    local session = self.session
    skynet.send(".logon", "lua", "logout", session.uid, session.fd)
    if session.handle then
        local ret = skynet.call(session.handle, "lua", "offline", session.uid)
        logger.debug("player close code:%d, err:%s", ret.code, ret.err)
    end
    self.session = nil
    return true
end)

socketapp.use("^kick$", function (self)
    local session = self.session
    if not session then
        return
    end
    logger.debug("kick session:%s", session:tostring())
    skynet.fork(function ( ... )
        if session.ws then
            session.ws:close()
        end
    end)
end)

socketapp.use("^shut$", function (self)
    local session = self.session
    if not session then
        return
    end
    logger.debug("shut session:%s", session:tostring())
    skynet.fork(function ( ... )
        if session.ws then
            session.ws:close()
        end
    end)
end)

return socketapp
