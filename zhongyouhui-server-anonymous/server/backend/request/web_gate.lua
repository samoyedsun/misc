local skynet = require "skynet"
local logger = log4.get_logger("server_backend_request_web_gate")

local REQUEST = {}

-- 查看是否登录
function REQUEST:gate_logon(msg)
    local ok = skynet.call(".logon", "lua", "is_logon", msg.uid)
    return {flag = ok}
end

function REQUEST:gate_room(msg)
    --local ok = skynet.call(".room", "lua", "room_is_exist", msg.rid)
    --return {flag = ok}
    return {flag = false}
end

function REQUEST:gate_push(msg)
end

function REQUEST:gate_broadcast(msg)
end

local root = {}

function root.request(req)
    local name = req.params.name
    if not REQUEST[name] then
        return {code = code.ERROR_NAME_UNFOUND, err = code.ERROR_NAME_UNFOUND_MSG}
    end
    local msg
    if req.method == "GET" then
        msg = req.query
    else
        msg = cjson_decode(req.body)
    end
    local trace_err = ""
    local trace = function (e)
        trace_err = e .. debug.traceback()
    end
    local ok, res = xpcall(REQUEST[name], trace, req, msg)
    if not ok then
        logger.error("%s %s %s", req.path, tostring(msg), trace_err)
        return {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
    end
    return res
end

return root