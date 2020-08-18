local skynet = require "skynet"
local code = require "server.config.code"
local common_conf = require "server.config.common_conf"
local game_users_db = require "server.common.game_users_db"
local logger = log4.get_logger("server_lualib_logon_helper")

local UID_TO_LOGON = {}
local ONLINE_NUMBER = 0

local UID_TO_AUTH_CODE = {}
local AUTH_CODE_NUMBER = 0
local MONITOR_RID = 0

local CMD = {}

function CMD.logon(uid, fd, agent, reconnection)
    local old_connect_info = UID_TO_LOGON[uid]
    if old_connect_info then
        UID_TO_LOGON[uid] = {fd = fd, agent = agent}
        local fd = old_connect_info.fd
        local agent = old_connect_info.agent
        if reconnection then
            logger.info("shut uid %s fd %s agent %s", uid, fd, agent)
            pcall(skynet.call, agent, "lua", "emit", fd, "shut") -- 关连接
        else
            logger.info("kick uid %s fd %s agent %s", uid, fd, agent)
            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_user_kick", {})
            pcall(skynet.call, agent, "lua", "emit", fd, "kick") -- 踢下线
        end
        return
    end
    logger.info("logon uid:%s, fd:%s", uid, fd)
    UID_TO_LOGON[uid] = {fd = fd, agent = agent}
    ONLINE_NUMBER = ONLINE_NUMBER + 1
    game_users_db:update_game_user_online(uid, common_conf.ONLINE)
    --skynet.send(".club", "lua", "update_club_chat_member", uid)
    --skynet.send(".club", "lua", "update_single_chat_member", uid)
end

function CMD.logout(uid, fd)
    if not UID_TO_LOGON[uid] then
        return
    end
    if UID_TO_LOGON[uid].fd ~= fd then
        return
    end
    logger.info("logout uid:%s, fd:%s", uid, fd)
    UID_TO_LOGON[uid] = nil
    ONLINE_NUMBER = ONLINE_NUMBER - 1
    game_users_db:update_game_user_online(uid, common_conf.OFFLINE)
    --skynet.send(".club", "lua", "update_club_chat_member", uid)
    --skynet.send(".club", "lua", "update_single_chat_member", uid)
end

function CMD.is_logon(uid)
    if UID_TO_LOGON[uid] then
        return true
    end
    return false
end

function CMD.agent(uid)
    return UID_TO_LOGON[uid]
end

function CMD.broadcast(name, msg)
    local agent = {}
    for _, v in pairs(UID_TO_LOGON) do
        agent[v.agent] = true
    end
    local agents = table.indices(agent)
    for _, agent in ipairs(agents) do
        pcall(skynet.send, agent, "lua", "s2c_broadcast", name, args)
    end
end

function CMD.set_auth_code_info(uid, auth_code, phone_number)
    UID_TO_AUTH_CODE[uid] = {
        auth_code = auth_code,
        phone_number = phone_number
    }
    AUTH_CODE_NUMBER = AUTH_CODE_NUMBER + 1
    create_timeout(common_conf.AUTH_CODE_VALID_TIME * 100, function()
        UID_TO_AUTH_CODE[uid] = nil
        AUTH_CODE_NUMBER = AUTH_CODE_NUMBER - 1
    end)
end

function CMD.get_auth_code_info(uid)
    local auth_code_info = UID_TO_AUTH_CODE[uid]
    if not auth_code_info then
        return false
    end
    return true, auth_code_info
end

function CMD.set_anonymous_monitor_rid(rid)
    MONITOR_RID = rid
end

function CMD.get_anonymous_monitor_rid()
    return MONITOR_RID
end

function CMD.sync_anonymous_monitor(data)
    local logon = UID_TO_LOGON[10000000]
    if logon then
        local agent = logon.agent
        local fd = logon.fd
        pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_room_anonymous_monitor", data)
    end
end

function CMD.fetch_module_info()
    local uid_to_logon_list = {}
    for uid, logon in pairs(UID_TO_LOGON) do
        table.insert(uid_to_logon_list, {uid = uid, logon = logon})
    end
    local self_info = {
        uid_to_logon_list = uid_to_logon_list,
        online_number = ONLINE_NUMBER
    }
    return cjson_encode(self_info)
end

function CMD.update_module_info(tmp_info)
    local self_info = cjson_decode(tmp_info)
    for _, obj in ipairs(self_info.uid_to_logon_list) do
    	UID_TO_LOGON[obj.uid] = obj.logon
    end
    ONLINE_NUMBER = self_info.online_number

    logger.info("online user number:%d", ONLINE_NUMBER)
    logger.info("exist auth code number:%d", AUTH_CODE_NUMBER)
end

return CMD