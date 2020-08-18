local skynet = require "skynet"
local hotfix = require "hotfix"
local code = require "server.config.code"
local game_db = require "server.common.game_db"
local game_users_db = require "server.common.game_users_db"
local game_rooms_db = require "server.common.game_rooms_db"
local game_clubs_db = require "server.common.game_clubs_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local common_util = require "server.common.common_util"
local logger = log4.get_logger("server_frontend_request_socket_room")

local REQUEST = {}

function REQUEST:room_create_settings(msg)
    local big_game_mode = msg.big_game_mode
    if type(big_game_mode) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not common_util:value_member(common_conf.BIG_GAME_MODE_LIST, big_game_mode) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local round_limit_list = shake_dice_conf.ROUND_LIMIT_LIST
    if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
        round_limit_list = shake_dice_conf.ROUND_LIMIT_LIST_CLUB_CHIP
    end
    local data = {
        round_limit_list = round_limit_list,
        user_limit_list = shake_dice_conf.USER_LIMIT_LIST,
        game_mode_list = shake_dice_conf.GAME_MODE_LIST,
        bet_slot_limit_list = shake_dice_conf.BET_SLOT_LIMIT_LIST,
        carry_score_list = shake_dice_conf.CARRY_SCORE_LIST
    } 
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:room_create(msg)
    local uid = msg.uid
    local game_type = msg.game_type
    local round_limit = msg.round_limit
    local user_limit = msg.user_limit
    local game_mode = msg.game_mode
    local bet_slot_limit = msg.bet_slot_limit
    local carry_score = msg.carry_score
    local bet_tao_switch = msg.bet_tao_switch
    local big_game_mode = msg.big_game_mode
    local need_bet_before_nuo = msg.need_bet_before_nuo
    local cid = msg.cid

    -- 以后要去掉
    local need_bet_before_nuo = need_bet_before_nuo or common_conf.NEED_BET_BEFORE_NUO_OF_NO
    
    if type(uid) ~= "number" or
        type(game_type) ~= "number" or
        type(round_limit) ~= "number" or
        type(user_limit) ~= "number" or
        type(game_mode) ~= "number" or
        type(bet_slot_limit) ~= "number" or
        type(carry_score) ~= "number" or
        type(bet_tao_switch) ~= "number" or
        type(big_game_mode) ~= "number" or
        type(need_bet_before_nuo) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local round_limit_list = shake_dice_conf.ROUND_LIMIT_LIST
    if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
        round_limit_list = shake_dice_conf.ROUND_LIMIT_LIST_CLUB_CHIP
    end
    if (not common_util:value_member(common_conf.GAME_TYPE_LIST, game_type)) or
        (not common_util:value_member(round_limit_list, round_limit)) or
        (not common_util:value_member(shake_dice_conf.USER_LIMIT_LIST, user_limit)) or
        (not common_util:value_member(shake_dice_conf.GAME_MODE_LIST, game_mode)) or
        (not common_util:value_member(shake_dice_conf.BET_SLOT_LIMIT_LIST, bet_slot_limit)) or
        (not common_util:value_member(shake_dice_conf.CARRY_SCORE_LIST, carry_score)) or
        (not common_util:value_member(common_conf.BIG_GAME_MODE_LIST, big_game_mode)) or
        (not common_util:value_member(common_conf.NEED_BET_BEFORE_NUO_LIST, need_bet_before_nuo)) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    if common_util:value_member(common_conf.BIG_GAME_MODE_CLUB_LIST, big_game_mode) then
        if type(cid) ~= "number" then
            return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
        end
        local ok = game_clubs_db:is_exist_game_club(cid)
        if not ok then
            return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
        end
        local ok = game_clubs_db:is_exist_club_member(cid, uid)
        if not ok then
            return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
        end
        local member = game_clubs_db:fetch_club_member(cid, uid)
        local status = member.status
        if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
            return {code = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION, err = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION_MSG}
        end
    else
        cid = 0
    end
    local status = game_db:fetch_game_operations_status()
    if status == common_conf.GAME_OPERATIONS_STATUS_STOP then
        local err = code.ERROR_GAME_STOP_OPERATIONS_CAN_NOT_CREATE_ROOM_MSG
        return {code = code.ERROR_GAME_STOP_OPERATIONS_CAN_NOT_CREATE_ROOM, err = err}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local rid = game_users_db:fetch_game_user_rid(uid)
    if rid ~= common_conf.NOT_IN_ROOM then
        return {code = code.ERROR_ALREADY_IN_ROOM, err = code.ERROR_ALREADY_IN_ROOM_MSG}
    end
	
    local room_card = 0
    local consumer_uid = 0
    if common_util:value_member(common_conf.BIG_GAME_MODE_CLUB_LIST, big_game_mode) then
        local ok = game_clubs_db:is_exist_game_club(cid)
        if not ok then
            return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
        end
        local owner = game_clubs_db:fetch_club_owner_by_cid(cid)
        local owner_uid = owner.uid
        local game_user = game_users_db:fetch_game_user_by_uid(owner_uid)
        room_card = game_user.room_card
        consumer_uid = game_user.uid
    else
        local game_user = game_users_db:fetch_game_user_by_uid(uid)
        room_card = game_user.room_card
        consumer_uid = game_user.uid
    end

    local expend_room_card_cond_map = common_conf.EXPEND_ROOM_CARD_COND_MAP
    if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
        expend_room_card_cond_map = common_conf.EXPEND_ROOM_CARD_COND_MAP_CLUB_CHIP
    end
    local expend_room_card = 0
    for k, v in ipairs(expend_room_card_cond_map) do
        if v.round_limit == round_limit and v.user_limit == user_limit then
            expend_room_card = v.room_card
        end
    end
    if room_card < expend_room_card then
        local err = code.ERROR_ROOM_CARD_LACK_CAN_NOT_CREATE_ROOM_MSG
        return {code = code.ERROR_ROOM_CARD_LACK_CAN_NOT_CREATE_ROOM, err = err}
    end
    local ok, room_number = game_db:fetch_room_number()
    if not ok then
        return {code = code.ERROR_NO_ROOM_NUMBER_AVAILABLE, err = code.ERROR_NO_ROOM_NUMBER_AVAILABLE_MSG}
    end
    local rid = game_db:fetch_rid()
    game_db:attach_use_room_number_rid(room_number, rid)

    local banker_uid = 0
    if game_mode == shake_dice_conf.FIXED_BRANKER then
        banker_uid = uid
    end
    local skynet_service_id = hotfix.start_hotfix_service("skynet", "server/service/srv_room", "rid:" .. rid)
    game_rooms_db:insert_game_rooms({
        owner_uid = uid, round_limit = round_limit, user_limit = user_limit, game_mode = game_mode, bet_slot_limit = bet_slot_limit,
        carry_score = carry_score, banker_uid = banker_uid, game_type = game_type, big_game_mode = big_game_mode, cid = cid,
        room_number = room_number, rid = rid, skynet_service_id = skynet_service_id, status = shake_dice_conf.GAME_STATE_WAIT_PLAY, round_amount = 0,
        user_amount = 0
    })
    local create_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
    local finish_date = os.date("%Y-%m-%d %H:%M:%S", 0)
    game_db:insert_room_records({
        rid = rid, room_number = room_number, owner_uid = uid, consumer_uid = consumer_uid, expend_room_card = expend_room_card,
        expend = common_conf.EXPENDED, status = common_conf.ROOM_UNCLOSE, round_limit = round_limit, user_limit = user_limit, bet_slot_limit = bet_slot_limit,
        carry_score = carry_score, game_type = game_type, game_mode = game_mode, big_game_mode = big_game_mode, cid = cid, 
        create_date = create_date, finish_date = finish_date
    })
    local param = {
        owner_uid = uid, round_limit = round_limit, user_limit = user_limit, game_mode = game_mode, bet_slot_limit = bet_slot_limit,
        carry_score = carry_score, game_type = game_type, big_game_mode = big_game_mode, cid = cid, room_number = room_number,
        rid = rid, status = shake_dice_conf.GAME_STATE_WAIT_PLAY, expend_room_card = expend_room_card, bet_tao_switch = bet_tao_switch,
        need_bet_before_nuo = need_bet_before_nuo
    }
    skynet.call(skynet_service_id, "lua", "create", param)

    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local session = self.session
    local param = {
        uid = uid,
        game_user = game_user,
        user_net = {
            ip = session.ip,
            fd = session.fd,
            agent = session.agent
        }
    }
    session.uid = uid
    session.handle = skynet_service_id
    return skynet.call(skynet_service_id, "lua", "join", param)
end

function REQUEST:room_join(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local tmp_rid = game_users_db:fetch_game_user_rid(uid)
    if tmp_rid ~= common_conf.NOT_IN_ROOM then
        return {code = code.ERROR_ALREADY_IN_ROOM, err = code.ERROR_ALREADY_IN_ROOM_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local big_game_mode = game_room.big_game_mode
    if common_util:value_member(common_conf.BIG_GAME_MODE_CLUB_LIST, big_game_mode) then
        local cid = game_room.cid
        local ok = game_clubs_db:is_exist_game_club(cid)
        if not ok then
            return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
        end
        local ok = game_clubs_db:is_exist_club_member(cid, uid)
        if not ok then
            return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
        end
    end
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local session = self.session
    local param = {
        uid = uid,
        game_user = game_user,
        user_net = {
            ip = session.ip,
            fd = session.fd,
            agent = session.agent
        }
    }
    session.uid = uid
    session.handle = game_room.skynet_service_id
    return skynet.call(game_room.skynet_service_id, "lua", "join", param)
end

function REQUEST:room_ready(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "ready", uid)
end

function REQUEST:room_start(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "start", uid)
end

function REQUEST:room_leave(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "leave", uid)
end

function REQUEST:room_kick(msg)
    local uid = msg.uid
    local rid = msg.rid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "kick", uid, target_uid)
end

function REQUEST:room_grab_banker(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "grab_banker", uid)
end

function REQUEST:room_shake_dice(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "shake_dice", uid)
end

function REQUEST:room_open_dice(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "open_dice", uid)
end

function REQUEST:room_bet_dan(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot = msg.slot
    local chip_type = msg.chip_type
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot) ~= "number" or
        type(chip_type) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(shake_dice_conf.CHIP_TYPE_LIST, chip_type) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    if not table.member(bet_slot_list, slot) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_dan", uid, slot, chip_type)
end

function REQUEST:room_bet_bao_zi(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot = msg.slot
    local amount = msg.amount
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot) ~= "number" or
        type(amount) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    if not table.member(bet_slot_list, slot) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_bao_zi", uid, slot, amount)
end

function REQUEST:room_bet_lian_chuan(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot_list = msg.slot_list
    local amount = msg.amount
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot_list) ~= "table" or
        type(amount) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
    if not common_util:list_member(double_combined_slot_list, slot_list) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_lian_chuan", uid, slot_list, amount)
end

function REQUEST:room_bet_nuo(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot_list = msg.slot_list
    local amount = msg.amount
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot_list) ~= "table" or
        type(amount) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
    if not common_util:list_member(double_combined_slot_list, slot_list) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_nuo", uid, slot_list, amount)
end

function REQUEST:room_bet_tao(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot_list = msg.slot_list
    local amount = msg.amount
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot_list) ~= "table" or
        type(amount) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
    if not common_util:list_member(double_combined_slot_list, slot_list) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_tao", uid, slot_list, amount)
end

function REQUEST:room_bet_nuo_limit(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot_list = msg.slot_list
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot_list) ~= "table" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
    if not common_util:list_member(double_combined_slot_list, slot_list) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_nuo_limit", uid, slot_list)
end

function REQUEST:room_bet_tao_limit(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot_list = msg.slot_list
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot_list) ~= "table" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
    if not common_util:list_member(double_combined_slot_list, slot_list) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_tao_limit", uid, slot_list)
end

function REQUEST:room_bet_bao_zi_limit(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot = msg.slot
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    if not table.member(bet_slot_list, slot) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_bao_zi_limit", uid, slot)
end

function REQUEST:room_bet_lian_chuan_limit(msg)
    local uid = msg.uid
    local rid = msg.rid
    local slot_list = msg.slot_list
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(slot_list) ~= "table" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
    if game_room.game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
        bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
    end
    local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
    if not common_util:list_member(double_combined_slot_list, slot_list) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    return skynet.call(game_room.skynet_service_id, "lua", "bet_lian_chuan_limit", uid, slot_list)
end

function REQUEST:room_chat(msg)
    local uid = msg.uid
    local rid = msg.rid
    local chat_info = msg.chat_info
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(chat_info) ~= "table" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if type(chat_info.type) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if chat_info.type == shake_dice_conf.CHAT_TYPE_FACE and
        type(chat_info.id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if chat_info.type == shake_dice_conf.CHAT_TYPE_VOICE and
        type(chat_info.id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if chat_info.type == shake_dice_conf.CHAT_TYPE_WORDS and
        type(chat_info.words) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end

    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "chat", uid, chat_info)
end

function REQUEST:room_voice(msg)
    local uid = msg.uid
    local rid = msg.rid
    local content = msg.content
    local second = msg.second
    if type(uid) ~= "number" or 
        type(rid) ~= "number" or
        type(content) ~= "string" or
        type(second) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "voice", uid, content, second)
end

function REQUEST:room_giving_chip(msg)
    local source_uid = msg.uid
    local rid = msg.rid
    local target_uid = msg.target_uid
    local amount = msg.amount
    if type(source_uid) ~= "number" or 
        type(rid) ~= "number" or
        type(target_uid) ~= "number" or
        type(amount) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if amount <= 0 then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(source_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "giving_chip", source_uid, target_uid, amount)
end

function REQUEST:room_info(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local session = self.session
    local user_net = {
        ip = session.ip,
        fd = session.fd,
        agent = session.agent
    }
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "info", uid, user_net)
end

function REQUEST:room_close_launch(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "close_launch", uid)
end

function REQUEST:room_close_agree(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "close_agree", uid)
end

function REQUEST:room_close_disagree(msg)
    local uid = msg.uid
    local rid = msg.rid
    if type(uid) ~= "number" or 
        type(rid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_rid(rid)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    return skynet.call(game_room.skynet_service_id, "lua", "close_disagree", uid)
end

function REQUEST:room_anonymous_monitor(msg)
    local room_number = msg.room_number
    if type(room_number) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_room_number(room_number)
    if not ok then
        return {code = code.ERROR_ROOM_UNFOUND, err = code.ERROR_ROOM_UNFOUND_MSG}
    end
    local game_room = game_rooms_db:fetch_game_room_by_room_number(room_number)
    skynet.send(".logon", "lua", "set_anonymous_monitor_rid", game_room.rid)
    return skynet.call(game_room.skynet_service_id, "lua", "anonymous_monitor")
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
