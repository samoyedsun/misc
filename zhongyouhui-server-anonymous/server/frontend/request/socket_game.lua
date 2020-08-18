local code = require "server.config.code"
local skynet = require "skynet"
local game_db = require "server.common.game_db"
local game_users_db = require "server.common.game_users_db"
local common_conf = require "server.config.common_conf"
local common_util = require "server.common.common_util"
local logger = log4.get_logger("server_frontend_request_socket_game")

local REQUEST = {}

function REQUEST:game_transfer_account_records(msg)
    local uid = msg.uid
    local amount = msg.amount
    local offset_id = msg.offset_id
    if type(uid) ~= "number" or 
        type(amount) ~= "number" or
        type(offset_id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if amount < common_conf.PAGE_AMOUNT_MIN or amount > common_conf.PAGE_AMOUNT_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local transfer_account_record_list = game_db:fetch_transfer_account_records(uid, offset_id, amount)
    local data = {
        transfer_account_record_list = transfer_account_record_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data}
end

function REQUEST:game_transfer_accounts(msg)
    local source_uid = msg.uid
    local target_uid = msg.target_uid
    local amount = msg.amount
    if type(source_uid) ~= "number" or 
        type(target_uid) ~= "number" or
        type(amount) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(source_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local source_game_user = game_users_db:fetch_game_user_by_uid(source_uid)
    if source_game_user.room_card < amount then
        local err = code.ERROR_ROOM_CARD_LACK_CAN_NOT_TRANSFER_ACCOUNTS_MSG
        return {code = code.ERROR_ROOM_CARD_LACK_CAN_NOT_TRANSFER_ACCOUNTS, err = err}
    end
    game_users_db:increase_game_user_room_card(-amount, source_uid)
    game_users_db:increase_game_user_room_card(amount, target_uid)


    local source_game_user = game_users_db:fetch_game_user_by_uid(source_uid)
    local target_game_user = game_users_db:fetch_game_user_by_uid(target_uid)
    local source_room_card = source_game_user.room_card
    local target_room_card = target_game_user.room_card

    local transfer_time = skynet_time()
    game_db:insert_transfer_account_records(source_uid, source_room_card, target_uid, target_room_card, transfer_time, amount)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:game_agency(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local agency = game_users_db:fetch_game_user_agency(uid)
    if agency ~= common_conf.NOT_AGENCY then
        agency = common_conf.IS_AGENCY
    end
    local ok, content = game_db:fetch_system_setting_content_by_type(common_conf.SYSTEM_SETTING_TYPE_AGENCY_INFO)
    if not ok then
        return {code = code.ERROR_AGENCY_INFO_UNFOUND, err = code.ERROR_AGENCY_INFO_UNFOUND_MSG}
    end
    local data = {
        agency = agency,
        content = content
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:game_scroll_bar(msg)
    local ok, content = game_db:fetch_system_setting_content_by_type(common_conf.SYSTEM_SETTING_TYPE_SCROLL_INFO)
    if not ok then
        return {code = code.ERROR_SCROLL_BAR_INFO_UNFOUND, err = code.ERROR_SCROLL_BAR_INFO_UNFOUND_MSG}
    end
    local data = {
        content = content
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:game_recharge_settings(msg)
    local tmp_type = msg.type
    if type(tmp_type) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.RECHARGE_TYPE_LIST, tmp_type) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_db:is_exist_recharge_setting_by_type(tmp_type)
    if not ok then
        return {code = code.ERROR_RECHARGE_SETTINGS_UNFOUND, err = code.ERROR_RECHARGE_SETTINGS_UNFOUND_MSG}
    end

    local recharge_settings = game_db:fetch_recharge_settings_by_type(tmp_type)
    local data = {
        recharge_settings = recharge_settings
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:game_recharge(msg)
    local uid = msg.uid
    local id = msg.id
    if type(id) ~= "number" or type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_db:is_exist_recharge_setting_by_id(id)
    if not ok then
        return {code = code.ERROR_RECHARGE_SETTINGS_UNFOUND, err = code.ERROR_RECHARGE_SETTINGS_UNFOUND_MSG}
    end

    local recharge_setting = game_db:fetch_recharge_setting_by_id(id)
    local tmp_type = recharge_setting.type
    local buy = recharge_setting.buy
    local price = recharge_setting.price
    
    if common_conf.RECHARGE_TYPE_GOLD_COIN == tmp_type then
        game_users_db:increase_game_user_gold_coin(buy, uid)
    elseif common_conf.RECHARGE_TYPE_DIAMOND == tmp_type then
        game_users_db:increase_game_user_diamond(buy, uid)
    elseif common_conf.RECHARGE_TYPE_ROOM_CARD == tmp_type then
        game_users_db:increase_game_user_room_card(buy, uid)
    end

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:game_room_card_setting(msg)
    local big_game_mode = msg.big_game_mode
    if type(big_game_mode) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not common_util:value_member(common_conf.BIG_GAME_MODE_LIST, big_game_mode) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local expend_room_card_cond_map = common_conf.EXPEND_ROOM_CARD_COND_MAP
    if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
        expend_room_card_cond_map = common_conf.EXPEND_ROOM_CARD_COND_MAP_CLUB_CHIP
    end
    local data = {
        expend_room_card_cond_list = expend_room_card_cond_map
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:game_notice_list(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local notice_list = game_db:fetch_game_notices()
    local data = {
        notice_list = notice_list
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