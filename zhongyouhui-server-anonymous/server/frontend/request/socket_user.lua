local code = require "server.config.code"
local skynet = require "skynet"
local game_db = require "server.common.game_db"
local wechat_tokens_db = require "server.common.wechat_tokens_db"
local game_users_db = require "server.common.game_users_db"
local game_clubs_db = require "server.common.game_clubs_db"
local common_conf = require "server.config.common_conf"
local http_util = require "server.common.http_util"
local common_util = require "server.common.common_util"
local logger = log4.get_logger("server_frontend_request_socket_user")

local REQUEST = {}

function REQUEST:user_auth(msg)
    local uid = msg.uid
    local token = msg.token
    local platform = msg.platform
    local reconnection = msg.reconnection
    if type(uid) ~= "number" or
        type(token) ~= "string" or
        type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.WECHAT_APP_PLATFORM_LIST, platform) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end

    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end

    if uid >= 1000000 then -- guest uid is 7 bit.
        self.session.auth = true
        self.session.uid = uid
        local fd = self.session.fd
        local agent = self.session.agent
        skynet.call(".logon", "lua", "logon", uid, fd, agent, reconnection)
        return {code = code.SUCCEED, err = code.SUCCEED_MSG}
    end

    local unionid = game_users_db:fetch_game_user_unionid_by_uid(uid)
    local ok = wechat_tokens_db:is_exist_wechat_token_by_unionid(platform, unionid)
    if not ok then
        return {code = code.ERROR_WECHAT_TOKEN_UNFOUND, err = code.ERROR_WECHAT_TOKEN_UNFOUND_MSG}
    end
    local wechat_token = wechat_tokens_db:fetch_wechat_token(platform, unionid)
    local openid = wechat_token.openid

    local ok, res = http_util.auth_wechat_token(platform, openid, token)
    if not ok then
        return {code = res.errcode, err = res.errmsg}
    end
    self.session.auth = true
    self.session.uid = uid
    local fd = self.session.fd
    local agent = self.session.agent
    skynet.call(".logon", "lua", "logon", uid, fd, agent, reconnection)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:user_info(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end

    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local data = {
        game_user = game_user
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:user_game_setting_fetch(msg)
    local uid = msg.uid

    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local game_user_setting = game_users_db:fetch_game_user_setting(uid)
    local data = {
        sound = game_user_setting.sound,
        music = game_user_setting.music,
        version = common_conf.GAME_VERSION
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:user_game_setting_update(msg)
    local uid = msg.uid
    local sound = msg.sound
    local music = msg.music

    if type(uid) ~= "number" or
        type(sound) ~= "number" or
        type(music) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if sound < common_conf.MUSIC_RANGE_MIN or sound > common_conf.MUSIC_RANGE_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    if music < common_conf.MUSIC_RANGE_MIN or music > common_conf.MUSIC_RANGE_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    game_users_db:update_game_user_setting(uid, sound, music)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:user_heartbeat(msg)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:user_send_auth_code(msg)
    local uid = msg.uid
    local phone_number = msg.phone_number
    if type(uid) ~= "number" or
        type(phone_number) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = common_util:check_phone_number(phone_number)
    if not ok then
        return {code = code.ERROR_PHONE_NUMBER_FORMAT, err = code.ERROR_PHONE_NUMBER_FORMAT_MSG}
    end
    local auth_code = common_util:random_number(4)
    skynet.call(".logon", "lua", "set_auth_code_info", uid, auth_code, phone_number)

    -- 发送验证码到手机
    http_util.send_auth_code(phone_number, auth_code)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:user_check_auth_code(msg)
    local uid = msg.uid
    local auth_code = msg.auth_code
    if type(uid) ~= "number" or
        type(auth_code) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok, auth_code_info = skynet.call(".logon", "lua", "get_auth_code_info", uid)
    if not ok then
        return {code = code.ERROR_AUTH_CODE_EXPIRED, err = code.ERROR_AUTH_CODE_EXPIRED_MSG}
    end
    if auth_code_info.auth_code ~= auth_code then
        return {code = code.ERROR_AUTH_CODE_EXPIRED, err = code.ERROR_AUTH_CODE_EXPIRED_MSG}
    end

    local phone_number = auth_code_info.phone_number
    local ok = game_users_db:is_exist_game_user_by_phone_number(phone_number)
    local gift = 0
    if ok then
        local target_uid = game_users_db:fetch_game_user_uid_by_phone_number(phone_number)
        game_users_db:update_game_user_phone_number(target_uid, "")
    else
        gift = common_conf.BOUND_PHONE_NUMBER_GIFT_ROOM_CARD
        game_users_db:increase_game_user_room_card(gift, uid)
    end
    game_users_db:update_game_user_phone_number(uid, phone_number)

    local data = {
        gift = gift
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:user_room_record(msg)
    local uid = msg.uid
    local cid = msg.cid
    local amount = msg.amount
    local offset_id = msg.offset_id
    if type(uid) ~= "number" or 
        type(amount) ~= "number" or
        type(offset_id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    if amount < common_conf.PAGE_AMOUNT_MIN or amount > common_conf.PAGE_AMOUNT_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    if type(cid) == "number" then
        local ok = game_clubs_db:is_exist_game_club(cid)
        if not ok then
            return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
        end
        game_db:curtail_user_room_records(uid, cid)
        local room_record_list = game_db:fetch_user_room_records(uid, offset_id, amount, cid)
        local data = {
            room_record_list = room_record_list
        }
        return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
    end
    game_db:curtail_user_room_records(uid)
    local room_record_list = game_db:fetch_user_room_records(uid, offset_id, amount)
    local data = {
        room_record_list = room_record_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:user_bound_invite_code(msg)
    local uid = msg.uid
    local invite_code = msg.invite_code
    if type(uid) ~= "number" or 
        type(invite_code) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_db:is_exist_invite_code_by_invite_code(invite_code)
    if not ok then
        return {code = code.ERROR_INVITE_CODE_UNFOUND, err = code.ERROR_INVITE_CODE_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_invite_code(uid)
    if ok then
        return {code = code.ERROR_INVITE_CODE_ALREADY_BOUND, err = code.ERROR_INVITE_CODE_ALREADY_BOUND_MSG}
    end
    local ok = game_db:is_exist_invite_code_by_uid(uid)
    if ok then
        local err = code.ERROR_PARTNER_CAN_NOT_BOUND_INVITE_CODE_MSG
        return {code = code.ERROR_PARTNER_CAN_NOT_BOUND_INVITE_CODE, err = err}
    end

    local invite_code_info = game_db:fetch_invite_code_by_id(invite_code)
    local role = invite_code_info.role

    local tmp_gift = invite_code_info.next_agent_bound_invite_code_gift_amount
    local tmp_type = invite_code_info.next_agent_bound_invite_code_gift_type
    if role == common_conf.INVITE_CODE_ROLE_PARTNER then
        tmp_gift = invite_code_info.super_agent_bound_invite_code_gift_amount
        tmp_type = invite_code_info.super_agent_bound_invite_code_gift_type

        local target_role = common_conf.INVITE_CODE_ROLE_SUPER_AGENT -- 为代理生成邀请码
        local next_agent_recharge_discount = invite_code_info.next_agent_recharge_discount
        local next_agent_recharge_current_agent_rebate = invite_code_info.next_agent_recharge_current_agent_rebate
        local next_agent_bound_invite_code_gift_amount = invite_code_info.next_agent_bound_invite_code_gift_amount
        local next_agent_bound_invite_code_gift_type = invite_code_info.next_agent_bound_invite_code_gift_type
        game_db:insert_invite_code_for_agent(
            uid, target_role,
            next_agent_recharge_discount,
            next_agent_recharge_current_agent_rebate,
            next_agent_bound_invite_code_gift_amount,
            next_agent_bound_invite_code_gift_type)
        -- 如果是合伙人的邀请码，就将自己设为代理.
        game_users_db:update_game_user_agency(uid, common_conf.IS_AGENCY)
    end
    game_users_db:update_game_user_invite_code(uid, invite_code)

    if common_conf.RECHARGE_TYPE_GOLD_COIN == tmp_type then
        game_users_db:increase_game_user_gold_coin(tmp_gift, uid)
    elseif common_conf.RECHARGE_TYPE_DIAMOND == tmp_type then
        game_users_db:increase_game_user_diamond(tmp_gift, uid)
    elseif common_conf.RECHARGE_TYPE_ROOM_CARD == tmp_type then
        game_users_db:increase_game_user_room_card(tmp_gift, uid)
    end

    local data = {
        gift = tmp_gift
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

local root = {}

function root:request(name, msg)
    if not REQUEST[name] then
        return {code = code.ERROR_NAME_UNFOUND, err = code.ERROR_NAME_UNFOUND_MSG}
    end

    local trace_err = ""
    local trace = function (e)
        trace_err = e .. debug.traceback()
    end
    local ok, res = xpcall(REQUEST[name], trace, self, msg)
    if not ok then
        logger.error("%s %s %s", name, tostring(msg), trace_err)
        return {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
    end
    return res
end

return root