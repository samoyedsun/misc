local skynet = require "skynet"
local socketproto = require "server.frontend.socketproto"
local socketapp = require "server.frontend.socketapp"
local websocket = require "websocket"
local logger = log4.get_logger("server_frontend_wsapp")

local CMD = {}
local SOCKET_TO_CLIENT = {}

function CMD.close(fd, reason)
    local client = SOCKET_TO_CLIENT[fd]
    SOCKET_TO_CLIENT[fd] = nil
    if not client then
        return
    end
    client:emit("close", reason)        -- 清理工作
end

function CMD.emit(fd, ...)
    local client = SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    client:emit(...)
end

function CMD.info()
    for k, v in pairs(SOCKET_TO_CLIENT) do 
        logger.info("fd %s to client session %s", k, tostring(v.session))
    end
end

function CMD.exit()
    for k, v in pairs(SOCKET_TO_CLIENT) do 
        v:emit("kick")
    end
end

-- 注册 srv_web_agent CMD.xxx
for cmd, p in pairs(CMD) do 
    add_web_agent_cmd(cmd, p)
end

--- overide 重载 send_package
function socketproto.send_package(fd, package)
    local client = SOCKET_TO_CLIENT[fd] 
    if not client or not client.session or not client.session.ws then
        return false, "close"
    end

    local ws = client.session.ws
    local ok, reason = ws:send_binary(package)
    if not ok then
        CMD.close(fd, reason)
    end
    return ok, reason
end

-- websocket回调方法
local handler = {}

function handler.on_open(ws)
    logger.info("[ws on_open]: %s | %s | %s | %s", ws.fd, ws.client_terminated, ws.server_terminated, ws.addr)
    local fd = ws.fd
    local client = socketapp:new()
    SOCKET_TO_CLIENT[fd] = client
    local ip = ws.addr:match("([^:]+):?(%d*)$")
    local session = {
        ws = ws,
        fd = fd,
        agent = skynet.self(),
        addr = ws.addr,
        ip = ip
    }
    client:emit("start", session)
end

function handler.on_message(ws, msg)
    logger.info("[ws on_message]: %s | %s | %s | %s", ws.fd, ws.client_terminated, ws.server_terminated, ws.addr)
    local fd = ws.fd
    local client =  SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    client:emit("c2s", msg, #msg)
end

function handler.on_error(ws, error)
    local fd = ws.fd
    logger.info("[ws on_error]: %s | %s | %s | %s | error:%s", fd, ws.client_terminated, ws.server_terminated, ws.addr, error)
    local client =  SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    CMD.close(fd, msg)
 end

function handler.on_close(ws, fd, code, reason)
    fd = fd or ws.fd
    logger.info("[ws on_close]: %s | %s | %s | %s | code:%s | reason:%s", fd, ws.client_terminated, ws.server_terminated, ws.addr, type(code), type(reason))
    local client =  SOCKET_TO_CLIENT[fd]
    if not client then
        return
    end
    CMD.close(fd, reason)
end 

local root = {}

--- http升级协议成websocket协议
function root.process(req, res)
    local fd = req.fd 
    local ws, err  = websocket.new(req.fd, req.addr, req.headers, handler)
    if not ws then
        res.body = err
        return false
    end
    ws:start()
    return true
end

return root