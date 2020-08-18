local skynet = require "skynet"
local code = require "server.config.code"
local game_db = require "server.common.game_db"
local game_rooms_db = require "server.common.game_rooms_db"
local game_users_db = require "server.common.game_users_db"
local game_clubs_db = require "server.common.game_clubs_db"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_lualib_club_helper")

local fetch_club_list_by_uid = function(uid)
    local club_list = game_clubs_db:fetch_club_list_by_uid(uid)
    for k, v in ipairs(club_list) do
        v.room_amount = game_rooms_db:fetch_game_room_amount(v.cid)
    end
    return club_list
end

local CMD = {}

function CMD.fetch_club_list_by_uid(uid)
    return fetch_club_list_by_uid(uid)
end

function CMD.club_room_list_change(cid)
    local room_list = game_rooms_db:fetch_game_rooms_by_cid(cid)

    local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)
    for k, member in ipairs(club_member_list) do
        local uid = member.uid
        local ok = skynet.call(".logon", "lua", "is_logon", uid)
        if ok then
            local logon = skynet.call(".logon", "lua", "agent", uid)
            local fd = logon.fd
            local agent = logon.agent
            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_room_list_change", {
                room_list = room_list,
                cid = cid
            })

            -- 俱乐部列表改变时改变俱乐部列表,因为俱乐部列表里有个房间数量.
            local club_list = fetch_club_list_by_uid(uid)
            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_list_change", {
                club_list = club_list
            })
        end
    end
end

function CMD.club_room_info_change(cid, rid)
    local game_room = game_rooms_db:fetch_game_room_by_rid(rid)
    local owner_uid = game_room.owner_uid
    if not owner_uid then
        local current_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
        logger.debug("这房间信息又没找到!rid:%d, date:%s, game_room:%s", rid, current_date, tostring(game_room))
        return nil
    end
    local game_user = game_users_db:fetch_game_user_by_uid(owner_uid)
    local owner_avatar = game_user.avatar
    local room_info = {
        game_type = game_room.game_type,
        game_mode = game_room.game_mode,
        room_number = game_room.room_number,
        bet_slot_limit = game_room.bet_slot_limit,
        user_limit = game_room.user_limit,
        round_limit = game_room.round_limit,
        round_amount = game_room.round_amount,
        user_amount = game_room.user_amount,
        owner_avatar = owner_avatar,
        status = game_room.status,
        big_game_mode = game_room.big_game_mode
    }
    local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)
    for k, member in ipairs(club_member_list) do
        local uid = member.uid
        local ok = skynet.call(".logon", "lua", "is_logon", uid)
        if ok then
            local logon = skynet.call(".logon", "lua", "agent", uid)
            local fd = logon.fd
            local agent = logon.agent
            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_room_info_change", {
                room_info = room_info
            })
        end
    end
end

function CMD.update_club_list(uid)
    local ok = skynet.call(".logon", "lua", "is_logon", uid)
    if ok then
        local logon = skynet.call(".logon", "lua", "agent", uid)
        local fd = logon.fd
        local agent = logon.agent
        local club_list = fetch_club_list_by_uid(uid)
        pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_list_change", {
            club_list = club_list
        })
    end
end

function CMD.update_club_red_dot(cid, red_dot)
    local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)
    for k, member in ipairs(club_member_list) do
        local status = member.status
        if status ~= common_conf.CLUB_MEMBER_STATUS_NORMAL then
            local uid = member.uid
            local ok = skynet.call(".logon", "lua", "is_logon", uid)
            if ok then
                local logon = skynet.call(".logon", "lua", "agent", uid)
                local fd = logon.fd
                local agent = logon.agent
                if not red_dot then
                    pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_cancel_red_dot", {
                        red_dot_id = common_conf.RED_DOT_ID_ON_CLUB_APPLY
                    })
                else
                    pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_show_red_dot", {
                        red_dot_id = common_conf.RED_DOT_ID_ON_CLUB_APPLY
                    })
                end
            end
        end
    end
end

function CMD.fetch_club_apply_list(uid, offset_id, amount)
    local club_member_list = game_clubs_db:fetch_club_members_by_uid(uid)
    local cid_list = {}
    for k, member in ipairs(club_member_list) do
        local cid = member.cid
        local status = member.status
        if status ~= common_conf.CLUB_MEMBER_STATUS_NORMAL then
            table.insert(cid_list, cid)
        end
    end
    local apply_list = {}
    if #cid_list > 0 then
        local club_apply_list = game_clubs_db:fetch_club_applys_cid(cid_list, offset_id, amount)
        for k, apply in ipairs(club_apply_list) do
            local uid = apply.uid
            local game_user = game_users_db:fetch_game_user_by_uid(uid)
            local nick_name = game_user.nick_name
            table.insert(apply_list, {
                uid = uid,
                nick_name = nick_name,
                cid = apply.cid,
                status = apply.status,
                id = apply.id
            })   
        end
    end
    return apply_list
end

function CMD.update_club_member_info(cid, uid)
    local member = game_clubs_db:fetch_club_member(cid, uid)
    local club_chip = member.club_chip
    local status = member.status
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local nick_name = game_user.nick_name
    local avatar = game_user.avatar
    local member_info = {
        uid = uid,
        nick_name = nick_name,
        avatar = avatar,
        club_chip = club_chip,
        status = status
    }
    local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)
    for k, member in ipairs(club_member_list) do
        local status = member.status
        if status ~= common_conf.CLUB_MEMBER_STATUS_NORMAL then
            local uid = member.uid
            local ok = skynet.call(".logon", "lua", "is_logon", uid)
            if ok then
                local logon = skynet.call(".logon", "lua", "agent", uid)
                local fd = logon.fd
                local agent = logon.agent
                pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_member_info_change", {
                    member_info = member_info
                })
            end
        end
    end
end

function CMD.club_chat_push(cid, club_chat)
    local club = game_clubs_db:fetch_game_club(cid)
    local club_name = club.club_name
    local chat_club = {
        cid = cid,
        club_name = club_name
    }
    local newest_time = game_clubs_db:fetch_club_chats_newest_time(cid)
    
    local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)
    for k, member in ipairs(club_member_list) do
        local uid = member.uid
        local unread_amount = member.unread_amount
        local remind = member.remind

        local ok = skynet.call(".logon", "lua", "is_logon", uid)
        if ok then
            local logon = skynet.call(".logon", "lua", "agent", uid)
            local fd = logon.fd
            local agent = logon.agent

            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_chat_info_change", {
                type = common_conf.CHAT_TYPE_GROUP,
                chat_club = chat_club,
                newest_time = newest_time,
                unread_amount = unread_amount,
                remind = remind
            })
            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_chat_push", {
                club_chat = club_chat
            })
        end
        game_clubs_db:increase_club_chats_unread_amount(cid, uid, 1)
    end
    game_clubs_db:curtail_club_chats(cid)
end

function CMD.single_chat_push(source_uid, target_uid, single_chat)
    local club_single_chat_list_special = game_db:fetch_single_chats_only_special(source_uid, target_uid)
    local single_chat_special = table.remove(club_single_chat_list_special)
    local newest_time = single_chat_special.newest_time
    local unread_amount = single_chat_special.unread_amount
    local remind = single_chat_special.remind

    local ok = skynet.call(".logon", "lua", "is_logon", source_uid)
    if ok then
        local logon = skynet.call(".logon", "lua", "agent", source_uid)
        local fd = logon.fd
        local agent = logon.agent
        pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_single_chat_push", {
            single_chat = single_chat
        })
    end
    local source_game_user = game_users_db:fetch_game_user_by_uid(source_uid)
    local chat_member = {
        uid = source_game_user.uid,
        avatar = source_game_user.avatar,
        nick_name = source_game_user.nick_name,
        online = source_game_user.online,
        rid = source_game_user.rid
    }
    local ok = skynet.call(".logon", "lua", "is_logon", target_uid)
    if ok then
        local logon = skynet.call(".logon", "lua", "agent", target_uid)
        local fd = logon.fd
        local agent = logon.agent

        pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_club_chat_info_change", {
            type = common_conf.CHAT_TYPE_SINGLE,
            chat_member = chat_member,
            newest_time = newest_time,
            unread_amount = unread_amount,
            remind = remind
        })
        
        pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_single_chat_push", {
            single_chat = single_chat
        })
    end
    game_db:curtail_single_chats(source_uid, target_uid)
end

function CMD.update_single_chat_member(uid)
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local nick_name = game_user.nick_name
    local avatar = game_user.avatar
    local online = game_user.online
    local rid = game_user.rid

    local club_chat_member = {
        uid = uid,
        nick_name = nick_name,
        avatar = avatar,
        online = online,
        rid = rid
    }

    local club_single_chat_list = game_db:fetch_single_chats_only(uid, uid)
    for k, v in ipairs(club_single_chat_list) do
        local source_uid = v.source_uid
        local target_uid = v.target_uid

        local contacts_uid = (source_uid ~= uid and {source_uid} or {target_uid})[1]
        local ok = skynet.call(".logon", "lua", "is_logon", contacts_uid)
        if ok then
            local logon = skynet.call(".logon", "lua", "agent", contacts_uid)
            local fd = logon.fd
            local agent = logon.agent
            pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_update_single_chat_member", {
                club_chat_member = club_chat_member
            })
        end
    end
end

function CMD.update_club_chat_member(uid)
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local nick_name = game_user.nick_name
    local avatar = game_user.avatar
    local online = game_user.online
    local rid = game_user.rid

    local club_chat_member = {
        uid = uid,
        nick_name = nick_name,
        avatar = avatar,
        online = online,
        rid = rid
    }

    local club_member_list = game_clubs_db:fetch_club_members_by_uid(uid)
    for k, member in ipairs(club_member_list) do
        local cid = member.cid

        local club_member_list = game_clubs_db:fetch_club_members_by_cid(cid)
        for k, member in ipairs(club_member_list) do
            local uid = member.uid
            local ok = skynet.call(".logon", "lua", "is_logon", uid)
            if ok then
                local logon = skynet.call(".logon", "lua", "agent", uid)
                local fd = logon.fd
                local agent = logon.agent
                pcall(skynet.call, agent, "lua", "emit", fd, "s2c", "on_update_club_chat_member", {
                    club_chat_member = club_chat_member
                })
            end
        end
    end
end

function CMD.club_chat_member_list(cid, offset_id, amount)
    local club_member_list = game_clubs_db:fetch_club_members_by_cid_page(cid, offset_id, amount)
    local member_list = {}
    for k, member in ipairs(club_member_list) do
        local uid = member.uid
        local id = member.id
        
        local game_user = game_users_db:fetch_game_user_by_uid(uid)
        local nick_name = game_user.nick_name
        local avatar = game_user.avatar
        local online = game_user.online
        local rid = game_user.rid

        table.insert(member_list, {
            id = id,
            uid = uid,
            nick_name = nick_name,
            avatar = avatar,
            online = online,
            rid = rid
        })
    end
    return member_list
end

function CMD.fetch_module_info()
    local self_info = {
    }
    return cjson_encode(self_info)
end

function CMD.update_module_info(tmp_info)
    local self_info = cjson_decode(tmp_info)
end

return CMD
