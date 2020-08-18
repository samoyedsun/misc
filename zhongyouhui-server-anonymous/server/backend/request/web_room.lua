local skynet = require "skynet"
local code = require "server.config.code"
local game_db = require "server.common.game_db"
local game_rooms_db = require "server.common.game_rooms_db"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_backend_request_web_room")

local REQUEST = {}

function REQUEST:stop_operations(msg)
    game_db:update_game_operations_status(common_conf.GAME_OPERATIONS_STATUS_STOP)
    local skynet_service_id_list = game_rooms_db:fetch_skynet_service_id_list()
    for k, skynet_service_id in ipairs(skynet_service_id_list) do
        skynet.send(skynet_service_id, "lua", "stop_operations")
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:open_operations(msg)
    game_db:update_game_operations_status(common_conf.GAME_OPERATIONS_STATUS_RUNNING)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:sync_block_data(msg)
    local block_data = msg.block_data
    local channel = msg.channel

    if type(channel) ~= "string" or
        type(block_data) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if channel ~= "crawler" and
        channel ~= "dfuse" then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end

    local data = skynet.call(".block", "lua", "broadcast", block_data, channel)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
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