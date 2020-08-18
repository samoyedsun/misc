local code = require "server.config.code"
local skynet = require "skynet"
local game_db = require "server.common.game_db"
local game_rooms_db = require "server.common.game_rooms_db"
local game_users_db = require "server.common.game_users_db"
local game_clubs_db = require "server.common.game_clubs_db"
local common_conf = require "server.config.common_conf"
local http_util = require "server.common.http_util"
local logger = log4.get_logger("server_frontend_request_socket_club")

local REQUEST = {}

function REQUEST:club_create(msg)
    local uid = msg.uid
    local club_name = msg.club_name
    if type(uid) ~= "number" or
        type(club_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local amount = game_clubs_db:fetch_game_club_amount(uid)
    if amount >= common_conf.CLUB_AMOUNT_LIMIT then
        local err = string.format(code.ERROR_CLUB_AMOUNT_REACH_LIMIT_MSG, amount)
        return {code = code.ERROR_CLUB_AMOUNT_REACH_LIMIT, err = err}
    end
    
    local owner_uid = uid
    local cid = game_db:fetch_cid()
    game_clubs_db:insert_game_club(cid, club_name, common_conf.DEFAULT_ANNOUNCEMENT, common_conf.DEFAULT_TOTAL_CLUB_CHIP)

    local club_chip = common_conf.INIT_CLUB_CHIP
    local status = common_conf.CLUB_MEMBER_STATUS_OWNER
    game_clubs_db:insert_club_member(cid, owner_uid, club_chip, status)
    skynet.send(".club", "lua", "update_club_list", uid)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_info(msg)
    local cid = msg.cid
    if type(cid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end

    local club = game_clubs_db:fetch_game_club(cid)
    local club_name = club.club_name
    local announcement = club.announcement
    local total_club_chip = club.total_club_chip
    local join_rank = club.join_rank
    local owner = game_clubs_db:fetch_club_owner_by_cid(cid)
    local owner_uid = owner.uid
    local member_list = game_clubs_db:fetch_club_members_by_cid_optimize(cid)
    local data = {
        cid = cid,
        club_name = club_name,
        announcement = announcement,
        total_club_chip = total_club_chip,
        owner_uid = owner_uid,
        member_list = member_list,
        join_rank = join_rank
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_update_announcement(msg)
    local uid = msg.uid
    local cid = msg.cid
    local announcement = msg.announcement
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(announcement) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if string.len(announcement) > common_conf.ANNOUNCEMENT_LENGTH_LIMIT then
        return {code = code.ERROR_CONTENT_REACH_LIMIT, err = code.ERROR_CONTENT_REACH_LIMIT_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
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
    
    game_clubs_db:update_game_club_announcement(cid, announcement)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_update_club_name(msg)
    local uid = msg.uid
    local cid = msg.cid
    local club_name = msg.club_name
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(club_name) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if string.len(club_name) > common_conf.CLUB_NAME_LENGTH_LIMIT then
        return {code = code.ERROR_CONTENT_REACH_LIMIT, err = code.ERROR_CONTENT_REACH_LIMIT_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
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
    if status ~= common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_IS_NOT_OWNER_CAN_NOT_OPERATION, err = code.ERROR_IS_NOT_OWNER_CAN_NOT_OPERATION_MSG}
    end
    
    game_clubs_db:update_game_club_club_name(cid, club_name)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_apply_list(msg)
    local uid = msg.uid
    local offset_id = msg.offset_id
    local amount = msg.amount

    if type(uid) ~= "number" or
        type(amount) ~= "number" or
        type(offset_id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if amount < common_conf.PAGE_AMOUNT_MIN or amount > common_conf.PAGE_AMOUNT_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end

    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end

    local apply_list = skynet.call(".club", "lua", "fetch_club_apply_list", uid, offset_id, amount)
    local data = {
        apply_list = apply_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_apply_agree(msg)
    local uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if ok then
        return {code = code.ERROR_ALREADY_IN_CLUB, err = code.ERROR_ALREADY_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local status = member.status
    if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION, err = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION_MSG}
    end
    local status = common_conf.CLUB_APPLY_STATUS_WAIT
    local ok = game_clubs_db:is_exist_club_apply(cid, target_uid, status)
    if not ok then
        return {code = code.ERROR_CLUB_APPLY_UNFOUND, err = code.ERROR_CLUB_APPLY_UNFOUND_MSG}
    end

    local status = common_conf.CLUB_APPLY_STATUS_AGREE
    game_clubs_db:update_club_apply_status(cid, target_uid, status)

    local ok = game_clubs_db:is_exist_old_club_member(cid, target_uid)
    if not ok then
        local club_chip = common_conf.INIT_CLUB_CHIP
        local status = common_conf.CLUB_MEMBER_STATUS_NORMAL
        game_clubs_db:insert_club_member(cid, target_uid, club_chip, status)
    else
        local status = common_conf.CLUB_MEMBER_STATUS_NORMAL
        game_clubs_db:update_club_member_status(status, cid, target_uid)
    end

    skynet.send(".club", "lua", "update_club_red_dot", cid, false)
    skynet.send(".club", "lua", "update_club_list", target_uid)
    
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_apply_disagree(msg)
    local uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if ok then
        return {code = code.ERROR_ALREADY_IN_CLUB, err = code.ERROR_ALREADY_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local status = member.status
    if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION, err = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION_MSG}
    end
    local status = common_conf.CLUB_APPLY_STATUS_WAIT
    local ok = game_clubs_db:is_exist_club_apply(cid, target_uid, status)
    if not ok then
        return {code = code.ERROR_CLUB_APPLY_UNFOUND, err = code.ERROR_CLUB_APPLY_UNFOUND_MSG}
    end

    local status = common_conf.CLUB_APPLY_STATUS_DISAGREE
    game_clubs_db:update_club_apply_status(cid, target_uid, status)
    skynet.send(".club", "lua", "update_club_red_dot", cid, false)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_list(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end

    local club_list = skynet.call(".club", "lua", "fetch_club_list_by_uid", uid)
    local data = {
        club_list = club_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_room_list(msg)
    local cid = msg.cid
    if type(cid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end

    local room_list = game_rooms_db:fetch_game_rooms_by_cid(cid)
    local data = {
        room_list = room_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_delete_member(msg)
    local uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local status = member.status
    if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_IS_NOT_MANAGER_CAN_NOT_DELETE_MEMBER, err = code.ERROR_IS_NOT_MANAGER_CAN_NOT_DELETE_MEMBER_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, target_uid)
    local status = member.status
    if status ~= common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_CAN_NOT_DELETE_MANAGER, err = code.ERROR_CAN_NOT_DELETE_MANAGER_MSG}
    end

    local rid = game_users_db:fetch_game_user_rid(target_uid)
    if rid ~= common_conf.NOT_IN_ROOM then
        local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
        if game_room.cid == cid then
            return {code = code.ERROR_ALREADY_IN_ROOM_CAN_NOT_OPERATION, err = code.ERROR_ALREADY_IN_ROOM_CAN_NOT_OPERATION_MSG}
        end
    end

    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    game_clubs_db:update_club_member_status(status, cid, target_uid)

    skynet.send(".club", "lua", "update_club_list", target_uid)
    
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_setup_manager(msg)
    local uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local status = member.status
    if status ~= common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_ONLY_OWNER_CAN_SETUP_MANAGER, err = code.ERROR_ONLY_OWNER_CAN_SETUP_MANAGER_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, target_uid)
    local status = member.status
    if status ~= common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_TARGET_ALREADY_IS_MANAGER, err = code.ERROR_TARGET_ALREADY_IS_MANAGER_MSG}
    end

    local status = common_conf.CLUB_MEMBER_STATUS_MANAGER
    game_clubs_db:update_club_member_status(status, cid, target_uid)
    skynet.send(".club", "lua", "update_club_list", uid)
    skynet.send(".club", "lua", "update_club_list", target_uid)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_cancel_manager(msg)
    local uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local status = member.status
    if status ~= common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_ONLY_OWNER_CAN_CANCEL_MANAGER, err = code.ERROR_ONLY_OWNER_CAN_CANCEL_MANAGER_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, target_uid)
    local status = member.status
    if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_TARGET_IS_NOT_MANAGER, err = code.ERROR_TARGET_IS_NOT_MANAGER_MSG}
    end
    
    local status = common_conf.CLUB_MEMBER_STATUS_NORMAL
    game_clubs_db:update_club_member_status(status, cid, target_uid)
    skynet.send(".club", "lua", "update_club_list", uid)
    skynet.send(".club", "lua", "update_club_list", target_uid)
    
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_transfer(msg)
    local uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(target_uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local status = member.status
    if status ~= common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_IS_NOT_OWNER_CAN_NOT_OPERATION, err = code.ERROR_IS_NOT_OWNER_CAN_NOT_OPERATION_MSG}
    end

    local status = common_conf.CLUB_MEMBER_STATUS_NORMAL
    game_clubs_db:update_club_member_status(status, cid, uid)
    local status = common_conf.CLUB_MEMBER_STATUS_OWNER
    game_clubs_db:update_club_member_status(status, cid, target_uid)

    skynet.send(".club", "lua", "update_club_list", uid)
    skynet.send(".club", "lua", "update_club_list", target_uid)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_quit(msg)
    local uid = msg.uid
    local cid = msg.cid
    if type(uid) ~= "number" or
        type(cid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
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
    if status == common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_OWNER_CAN_NOT_QUIT_CLUB, err = code.ERROR_OWNER_CAN_NOT_QUIT_CLUB_MSG}
    end

    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    game_clubs_db:update_club_member_status(status, cid, uid)
    
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_close(msg)
    local uid = msg.uid
    local cid = msg.cid
    if type(uid) ~= "number" or
        type(cid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
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
    if status ~= common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_ONLY_OWNER_CAN_CLOSE_CLUB, err = code.ERROR_ONLY_OWNER_CAN_CLOSE_CLUB_MSG}
    end
    local ok = game_rooms_db:is_exist_game_room_by_cid(cid)
    if ok then
        return {code = code.ERROR_ROOM_IS_ALL_CLOSE_CAN_NOT_CLOSE_CLUB, err = code.ERROR_ROOM_IS_ALL_CLOSE_CAN_NOT_CLOSE_CLUB_MSG}
    end
    local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)

    game_clubs_db:delete_game_club(cid)
    game_clubs_db:delete_club_members(cid)
    game_clubs_db:delete_club_applys(cid)
    game_clubs_db:delete_club_chats(cid)
    game_db:delete_club_chip_increase_records(cid)

    for k, member in ipairs(club_member_list) do
        local uid = member.uid
        skynet.send(".club", "lua", "update_club_list", uid)
    end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_apply(msg)
    local uid = msg.uid
    local cid = msg.cid
    if type(uid) ~= "number" or
        type(cid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if ok then
        return {code = code.ERROR_ALREADY_IN_CLUB, err = code.ERROR_ALREADY_IN_CLUB_MSG}
    end
    local status = common_conf.CLUB_APPLY_STATUS_WAIT
    local ok = game_clubs_db:is_exist_club_apply(cid, uid, status)
    if ok then
        return {code = code.ERROR_ALREADY_APPLY_JOIN_CLUB, err = code.ERROR_ALREADY_APPLY_JOIN_CLUB_MSG}
    end

    local status = common_conf.CLUB_APPLY_STATUS_WAIT
    game_clubs_db:insert_club_applys(uid, cid, status)
    skynet.send(".club", "lua", "update_club_red_dot", cid, true)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_check_red_dot(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local club_member_list = game_clubs_db:fetch_club_members_by_uid(uid)
    local flag = false
    for k, member in ipairs(club_member_list) do
        local club_apply_list = game_clubs_db:fetch_club_applys_cid_status(member.cid, common_conf.CLUB_APPLY_STATUS_WAIT)
        if common_conf.CLUB_MEMBER_STATUS_NORMAL ~= member.status and #club_apply_list > 0 then
            flag = true
        end
    end
    if not flag then
        return {code = code.ERROR_RED_DOT_UNFOUND, err = code.ERROR_RED_DOT_UNFOUND_MSG}
    end

    local data = {
        red_dot_id = common_conf.RED_DOT_ID_ON_CLUB_APPLY
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_chip_increase(msg)
    local source_uid = msg.uid
    local cid = msg.cid
    local target_uid = msg.target_uid
    local amount = msg.amount
    if type(source_uid) ~= "number" or
        type(cid) ~= "number" or
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
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, source_uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, target_uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    local member = game_clubs_db:fetch_club_member(cid, source_uid)
    local status = member.status
    if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
        return {code = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION, err = code.ERROR_IS_NOT_MANAGER_CAN_NOT_OPERATION_MSG}
    end
    local rid = game_users_db:fetch_game_user_rid(target_uid)
    if rid ~= common_conf.NOT_IN_ROOM then
        local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
        local ok = skynet.call(game_room.skynet_service_id, "lua", "is_bet", target_uid)
        if ok then
            return {code = code.ERROR_BET_CAN_NOT_OPERATION, err = code.ERROR_BET_CAN_NOT_OPERATION_MSG}
        else
            skynet.send(game_room.skynet_service_id, "lua", "update_score", target_uid, amount)
        end
    end
    
    game_clubs_db:increase_club_member_club_chip(amount, cid, target_uid)
    game_clubs_db:increase_game_club_total_club_chip(cid, amount)
    local increase_time = skynet_time()
    game_db:insert_club_chip_increase_records(cid, source_uid, target_uid, increase_time, amount)
    skynet.send(".club", "lua", "update_club_member_info", cid, target_uid)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_chip_increase_records(msg)
    local cid = msg.cid
    local uid = msg.uid
    local target_uid = msg.target_uid   -- 如果为真，就指定获取这个人的记录.
    local amount = msg.amount
    local offset_id = msg.offset_id
    if type(cid) ~= "number" or 
        type(uid) ~= "number" or 
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
    local club_chip_increase_record_list = {}
    if status == common_conf.CLUB_MEMBER_STATUS_NORMAL then
        club_chip_increase_record_list = game_db:fetch_club_chip_increase_records_normal(cid, uid, offset_id, amount)
    else
        if type(target_uid) ~= "number" then
            club_chip_increase_record_list = game_db:fetch_club_chip_increase_records_manager(cid, offset_id, amount)
        else
            local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
            if not ok then
                return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
            end
            club_chip_increase_record_list = game_db:fetch_club_chip_increase_records_normal(cid, target_uid, offset_id, amount)
        end
    end
    
    local data = {
        club_chip_increase_record_list = club_chip_increase_record_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_owner(msg)
    local cid = msg.cid
    if type(cid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local owner = game_clubs_db:fetch_club_owner_by_cid(cid)
    local owner_uid = owner.uid
    local game_user = game_users_db:fetch_game_user_by_uid(owner_uid)
    local data = {
        game_user = game_user
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_chat_member_list(msg)
    local uid = msg.uid
    local cid = msg.cid
    local amount = msg.amount
    local offset_id = msg.offset_id
    if type(uid) ~= "number" or 
        type(cid) ~= "number" or
        type(amount) ~= "number" or
        type(offset_id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if amount < common_conf.PAGE_AMOUNT_MIN or amount > common_conf.PAGE_AMOUNT_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end

    local club_chat_member_list = skynet.call(".club", "lua", "club_chat_member_list", cid, offset_id, amount)
    local data = {
        club_chat_member_list = club_chat_member_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_group_chat_list(msg)
    local uid = msg.uid
    local cid = msg.cid
    local amount = msg.amount
    local offset_id = msg.offset_id
    if type(uid) ~= "number" or 
        type(cid) ~= "number" or
        type(amount) ~= "number" or
        type(offset_id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if amount < common_conf.PAGE_AMOUNT_MIN or amount > common_conf.PAGE_AMOUNT_MAX then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    
    game_clubs_db:curtail_club_chats(cid)

    local club_group_chat_list = game_clubs_db:fetch_club_chats(cid, offset_id, amount)
    for k, v in ipairs(club_group_chat_list) do
        local game_user = game_users_db:fetch_game_user_by_uid(v.uid)
        v.avatar = game_user.avatar
        v.nick_name = game_user.nick_name
    end

    local data = {
        club_group_chat_list = club_group_chat_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_group_chat_push(msg)
    local uid = msg.uid
    local cid = msg.cid
    local tmp_type = msg.type
    local content = msg.content
    if type(uid) ~= "number" or 
        type(cid) ~= "number" or
        type(tmp_type) ~= "number" or
        type(content) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.CLUB_CHAT_TYPE_LIST, tmp_type) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_clubs_db:is_exist_game_club(cid)
    if not ok then
        return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_clubs_db:is_exist_club_member(cid, uid)
    if not ok then
        return {code = code.ERROR_NOT_IN_CLUB, err = code.ERROR_NOT_IN_CLUB_MSG}
    end
    
    local current_time = skynet_time()
    game_clubs_db:insert_club_chats(cid, uid, tmp_type, content, current_time)

    local club_chat_list = game_clubs_db:fetch_club_chats_newest(cid, uid)
    for k, v in ipairs(club_chat_list) do
        local game_user = game_users_db:fetch_game_user_by_uid(v.uid)
        v.avatar = game_user.avatar
        v.nick_name = game_user.nick_name
    end
    local club_chat = table.remove(club_chat_list)
    skynet.send(".club", "lua", "club_chat_push", cid, club_chat)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_single_chat_list(msg)
    local source_uid = msg.uid
    local target_uid = msg.target_uid
    local amount = msg.amount
    local offset_id = msg.offset_id
    if type(source_uid) ~= "number" or 
        type(target_uid) ~= "number" or
        type(amount) ~= "number" or
        type(offset_id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if amount < common_conf.PAGE_AMOUNT_MIN or amount > common_conf.PAGE_AMOUNT_MAX then
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
    
    game_db:curtail_single_chats(source_uid, target_uid)

    local game_user_tab = {}
    game_user_tab[source_uid] = game_users_db:fetch_game_user_by_uid(source_uid)
    game_user_tab[target_uid] = game_users_db:fetch_game_user_by_uid(target_uid)
    local club_single_chat_list = game_db:fetch_single_chats(source_uid, target_uid, offset_id, amount)
    for k, v in ipairs(club_single_chat_list) do
        v.source_avatar = game_user_tab[v.source_uid].avatar
        v.source_nick_name = game_user_tab[v.source_uid].nick_name
        v.target_avatar = game_user_tab[v.target_uid].avatar
        v.target_nick_name = game_user_tab[v.target_uid].nick_name
    end
    
    local data = {
        club_single_chat_list = club_single_chat_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_single_chat_push(msg)
    local source_uid = msg.uid
    local target_uid = msg.target_uid
    local tmp_type = msg.type
    local content = msg.content
    if type(source_uid) ~= "number" or 
        type(target_uid) ~= "number" or
        type(tmp_type) ~= "number" or
        type(content) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.CLUB_CHAT_TYPE_LIST, tmp_type) then
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
    

    local club_single_chat_list_special = game_db:fetch_single_chats_only_special(source_uid, target_uid)
    local single_chat_special = table.remove(club_single_chat_list_special)
    local remind = (single_chat_special and {single_chat_special.remind} or {common_conf.CHAT_REMIND})[1]
    local current_time = skynet_time()
    game_db:insert_single_chats(source_uid, target_uid, tmp_type, content, current_time, remind)

    local game_user_tab = {}
    game_user_tab[source_uid] = game_users_db:fetch_game_user_by_uid(source_uid)
    game_user_tab[target_uid] = game_users_db:fetch_game_user_by_uid(target_uid)
    local single_chat_list = game_db:fetch_single_chats_newest(source_uid, target_uid)
    for k, v in ipairs(single_chat_list) do
        v.source_avatar = game_user_tab[v.source_uid].avatar
        v.source_nick_name = game_user_tab[v.source_uid].nick_name
        v.target_avatar = game_user_tab[v.target_uid].avatar
        v.target_nick_name = game_user_tab[v.target_uid].nick_name
    end
    local single_chat = table.remove(single_chat_list)
    skynet.send(".club", "lua", "single_chat_push", source_uid, target_uid, single_chat)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_chat_info_list(msg)
    local uid = msg.uid
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end

    local chat_info_list = {}
    -- 获取群列表
    local club_member_list = game_clubs_db:fetch_club_members_by_uid(uid)
    for k, member in ipairs(club_member_list) do
        local cid = member.cid
        local unread_amount = member.unread_amount
        local remind = member.remind

        local club = game_clubs_db:fetch_game_club(cid)
        local club_name = club.club_name
        local chat_club = {
            cid = cid,
            club_name = club_name
        }
        local newest_time = game_clubs_db:fetch_club_chats_newest_time(cid)
        table.insert(chat_info_list, {
            type = common_conf.CHAT_TYPE_GROUP,
            chat_club = chat_club,
            newest_time = newest_time,
            unread_amount = unread_amount,
            remind = remind
        })
    end
    -- 获取单聊列表
    local club_single_chat_list = game_db:fetch_single_chats_only(uid, uid)
    local tmp_club_single_chat_tab = {}
    for k, v in ipairs(club_single_chat_list) do
        local newest_time = v.time
        local unread_amount = v.unread_amount
        local source_uid = v.source_uid
        local target_uid = v.target_uid
        local remind = v.remind

        if source_uid == uid then
            unread_amount = 0
        end

        local contacts_uid = (source_uid ~= uid and {source_uid} or {target_uid})[1]
        local game_user = game_users_db:fetch_game_user_by_uid(contacts_uid)
        local chat_member = {
            uid = contacts_uid,
            avatar = game_user.avatar,
            nick_name = game_user.nick_name,
            online = game_user.online,
            rid = game_user.rid
        }
        local club_single_chat = {
            type = common_conf.CHAT_TYPE_SINGLE,
            chat_member = chat_member,
            newest_time = newest_time,
            unread_amount = unread_amount,
            remind = remind
        }
        local old = tmp_club_single_chat_tab[contacts_uid]
        if old then
            if newest_time > old.newest_time then
                tmp_club_single_chat_tab[contacts_uid] = club_single_chat
            end
        else
            tmp_club_single_chat_tab[contacts_uid] = club_single_chat
        end
    end
    for k, v in pairs(tmp_club_single_chat_tab) do
        table.insert(chat_info_list, v)
    end

    local data = {
        chat_info_list = chat_info_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_chat_mark_read(msg)
    local uid = msg.uid
    local tmp_type = msg.type
    local target_uid = msg.target_uid
    local cid = msg.cid

    if type(uid) ~= "number" or
        type(tmp_type) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    if tmp_type == common_conf.CHAT_TYPE_SINGLE then
        if type(target_uid) ~= "number" then
            return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
        end
        local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
        if not ok then
            return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
        end
        game_db:reset_single_chats_unread_amount(target_uid, uid)
    elseif tmp_type == common_conf.CHAT_TYPE_GROUP then
        if type(cid) ~= "number" then
            return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
        end
        local ok = game_clubs_db:is_exist_game_club(cid)
        if not ok then
            return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
        end
        game_clubs_db:reset_club_chats_unread_amount(cid, uid)
    else
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_chat_update_remind(msg)
    local uid = msg.uid
    local tmp_type = msg.type
    local remind = msg.remind
    local target_uid = msg.target_uid
    local cid = msg.cid
    if type(uid) ~= "number" or
        type(tmp_type) ~= "number" or
        type(remind) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if remind ~= common_conf.CHAT_UNREMIND and remind ~= common_conf.CHAT_REMIND then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    if tmp_type == common_conf.CHAT_TYPE_SINGLE then
        if type(target_uid) ~= "number" then
            return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
        end
        local ok = game_users_db:is_exist_game_user_by_uid(target_uid)
        if not ok then
            return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
        end
        game_db:update_single_chats_remind(target_uid, uid, remind)
    elseif tmp_type == common_conf.CHAT_TYPE_GROUP then
        if type(cid) ~= "number" then
            return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
        end
        local ok = game_clubs_db:is_exist_game_club(cid)
        if not ok then
            return {code = code.ERROR_CLUB_UNFOUND, err = code.ERROR_CLUB_UNFOUND_MSG}
        end
        game_clubs_db:update_club_chats_remind(cid, uid, remind)
    else
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:club_rank_list(msg)
    local uid = msg.uid

    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end

    local current_time = skynet_time()
    local club_rank_list, club_rank_tick = skynet.call(".misc", "lua", "get_club_rank_list")
    local offset_tick = current_time - club_rank_tick
    if offset_tick > common_conf.CLUB_RANK_OFFSET_TICK then
        local cid_cond_list = common_conf.RANK_FAKE_CLUB_LIST[skynet.getenv("env")]
        local fake_club_rank_list = game_clubs_db:fetch_club_list_by_config_cid(cid_cond_list)
        -- 增加权重
        for k, v in ipairs(fake_club_rank_list) do
            v.id = math.random(10000, 99999)
        end
        -- 通过权重排序
        table.sort(fake_club_rank_list, function(v1, v2)
            return v1.id > v2.id
        end)
        -- 去掉权重
        for k, v in ipairs(fake_club_rank_list) do
            v.id = nil
        end
    
        -- 默认全部为假数据
        club_rank_list = {}
        for k, v in ipairs(fake_club_rank_list) do
            table.insert(club_rank_list, v)
        end

        -- 在假数据里前面一半随机一批位置，按顺序依次替换为真数据
        local cid_cond_list = common_conf.RANK_REAL_CLUB_LIST
        local real_club_rank_list = game_clubs_db:fetch_club_list_by_config_cid(cid_cond_list)
        local club_rank_yi_ban = math.floor(common_conf.CLUB_RANK_AMOUNT / 2)
        for i = 1, club_rank_yi_ban do
            if real_club_rank_list[i] then
                club_rank_list[i] = real_club_rank_list[i]
            end
        end

        -- 这些排行数据是最真的，其他都有点假，哈哈哈!
        local real_club_rank_list = game_clubs_db:fetch_club_list_by_expend_room_card_rank()
        
        -- 在假数据里后面一半随机一批位置，按顺序依次替换为真数据
        local real_club_rank_amount = #real_club_rank_list
        local residue = common_conf.CLUB_RANK_AMOUNT - common_conf.CLUB_RANK_FAKE_AMOUNT
        if real_club_rank_amount > (residue < club_rank_yi_ban and {residue} or {club_rank_yi_ban})[1] then
            real_club_rank_amount = (residue < club_rank_yi_ban and {residue} or {club_rank_yi_ban})[1]
        end
        
        local help_rand_idx_list = {}
        for i = club_rank_yi_ban + 1, common_conf.CLUB_RANK_AMOUNT do
            table.insert(help_rand_idx_list, i)
        end
        local rand_idx_list = {}
        for i = 1, real_club_rank_amount do
            local rand_idx = math.random(i, common_conf.CLUB_RANK_AMOUNT - club_rank_yi_ban)
            
            local tmp = help_rand_idx_list[rand_idx]
            help_rand_idx_list[rand_idx] = help_rand_idx_list[i]
            help_rand_idx_list[i] = tmp

            table.insert(rand_idx_list, tmp)
        end
        table.sort(rand_idx_list)
        
        for k, v in ipairs(rand_idx_list) do
            local idx = v
            club_rank_list[idx] = real_club_rank_list[k]
        end

        skynet.call(".misc", "lua", "set_club_rank_list", club_rank_list, current_time)
    end

    local data = {
        club_rank_list = club_rank_list
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:club_join_rank(msg)
    local uid = msg.uid
    local cid = msg.cid
    local join_rank = msg.join_rank
    if type(uid) ~= "number" or
        type(cid) ~= "number" or
        type(join_rank) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if join_rank ~= common_conf.CLUB_JOIN_RANK and join_rank ~= common_conf.CLUB_NOT_JOIN_RANK then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
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
    if status ~= common_conf.CLUB_MEMBER_STATUS_OWNER then
        return {code = code.ERROR_ONLY_OWNER_CAN_SETUP_JOIN_RANK, err = code.ERROR_ONLY_OWNER_CAN_SETUP_JOIN_RANK_MSG}
    end

    game_clubs_db:update_game_club_join_rank(cid, join_rank)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
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