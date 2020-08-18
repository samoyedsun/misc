local skynet = require "skynet"
local code = require "server.config.code"
local common_conf = require "server.config.common_conf"
local game_users_db = require "server.common.game_users_db"
local game_rooms_db = require "server.common.game_rooms_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local logger = log4.get_logger("server_frontend_request_web_game")

local REQUEST = {}

function REQUEST:fetch_rid(msg)
    local room_number = msg.room_number
    if type(room_number) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_room_number(room_number)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_room_number(room_number)
    local data = {
        rid = game_room.rid
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:in_room(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local rid = game_users_db:fetch_game_user_rid(uid)
    if rid == common_conf.NOT_IN_ROOM then
        return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
    end
    local data = {
        rid = rid
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:anonymous(msg)
    local uid = msg.uid
    local words = msg.words
    if type(uid) ~= "number" or
        type(words) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if words ~= "oa" and
        words ~= "ob" and
        words ~= "oc" and
        words ~= "od" and
        words ~= "oe" and
        words ~= "of" then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local chat_info = {
        type = shake_dice_conf.CHAT_TYPE_WORDS,
        words = words
    }
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local rid = game_users_db:fetch_game_user_rid(uid)
    if rid == common_conf.NOT_IN_ROOM then
        return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "chat", uid, chat_info)
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
