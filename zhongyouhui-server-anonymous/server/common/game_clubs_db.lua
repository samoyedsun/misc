local skynet = require "skynet"
local rpc_mysql = require "rpc_mysql"
local mysql_obj = rpc_mysql.get_mysql("zhongyouhui")
local common_db = require "server.common.common_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_common_game_clubs_db")

local root = {}

function root:insert_game_club(cid, club_name, announcement, total_club_chip)
    local command_insert_game_club = [[
        INSERT INTO `game_clubs`(
            `cid`, `club_name`, `announcement`, `total_club_chip`
        ) VALUES(
            %d, '%s', '%s', %d
        );
    ]]
    local command_insert_game_club = string.format(
        command_insert_game_club,
        cid, club_name, announcement, total_club_chip
    )
    mysql_obj:query(command_insert_game_club)
end

function root:insert_club_member(cid, uid, club_chip, status)
    local command_insert_club_member = [[
        INSERT INTO `club_members`(
            `cid`, `uid`, `club_chip`, `status`
        ) VALUES(
            %d, %d, %d, %d
        );
    ]]
    local command_insert_club_member = string.format(
        command_insert_club_member,
        cid, uid, club_chip, status
    )
    mysql_obj:query(command_insert_club_member)
end

function root:fetch_game_club_amount(uid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_fetch_game_club_amount = [[
        SELECT
            COUNT(1) `amount`
        FROM
            `club_members`
        WHERE
            `uid`=%d and `status`!=%d;
    ]]
    local command_fetch_game_club_amount = string.format(
        command_fetch_game_club_amount,
        uid, status
    )
    local res = mysql_obj:query(command_fetch_game_club_amount)
    local amount = 0
    while next(res) do
        local tmp = table.remove(res)
        amount = tmp.amount
    end
    return amount
end

function root:fetch_game_club(cid)
    local command_fetch_game_club = [[
        SELECT
            `cid`,
            `club_name`,
            `announcement`,
            `total_club_chip`,
            `join_rank`
        FROM
            `game_clubs`
        WHERE
            `cid`=%d
        LIMIT 1;
    ]]
    local command_fetch_game_club = string.format(
        command_fetch_game_club,
        cid
    )
    local res = mysql_obj:query(command_fetch_game_club)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.cid = tmp.cid
        results.club_name = tmp.club_name
        results.announcement = tmp.announcement
        results.total_club_chip = tmp.total_club_chip
        results.join_rank = tmp.join_rank
    end
    return results
end

function root:update_game_club_join_rank(cid, join_rank)
    local command_update_game_club_join_rank = [[
        UPDATE
            `game_clubs`
        SET
            `join_rank`=%d
        WHERE
            `cid`=%d
        LIMIT 1;
    ]]

    local command_update_game_club_join_rank = string.format(
        command_update_game_club_join_rank,
        join_rank,
        cid
    )
    mysql_obj:query(command_update_game_club_join_rank)
end

function root:update_game_club_announcement(cid, announcement)
    local command_update_game_club_announcement = [[
        UPDATE
            `game_clubs`
        SET
            `announcement`='%s'
        WHERE
            `cid`=%d
        LIMIT 1;
    ]]

    local command_update_game_club_announcement = string.format(
        command_update_game_club_announcement,
        announcement,
        cid
    )
    mysql_obj:query(command_update_game_club_announcement)
end

function root:update_game_club_club_name(cid, club_name)
    local command_update_game_club_club_name = [[
        UPDATE
            `game_clubs`
        SET
            `club_name`='%s'
        WHERE
            `cid`=%d
        LIMIT 1;
    ]]

    local command_update_game_club_club_name = string.format(
        command_update_game_club_club_name,
        club_name,
        cid
    )
    mysql_obj:query(command_update_game_club_club_name)
end

function root:increase_game_club_total_club_chip(cid, club_chip)
    local command_increase_game_club_total_club_chip = [[
        UPDATE
            `game_clubs`
        SET
            `total_club_chip`=`total_club_chip`+%d
        WHERE
            `cid`=%d
        LIMIT 1;
    ]]

    local command_increase_game_club_total_club_chip = string.format(
        command_increase_game_club_total_club_chip,
        club_chip,
        cid
    )
    mysql_obj:query(command_increase_game_club_total_club_chip)
end

function root:fetch_club_owner_by_cid(cid)
    local status = common_conf.CLUB_MEMBER_STATUS_OWNER
    local command_fetch_club_owner_by_cid = [[
        SELECT
            `cid`,
            `uid`,
            `club_chip`,
            `status`
        FROM
            `club_members`
        WHERE
            `cid`=%d and `status`=%d;
    ]]
    local command_fetch_club_owner_by_cid = string.format(
        command_fetch_club_owner_by_cid,
        cid, status
    )
    local res = mysql_obj:query(command_fetch_club_owner_by_cid)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.cid = tmp.cid
        results.uid = tmp.uid
        results.club_chip = tmp.club_chip
        results.status = tmp.status
    end
    return results
end

function root:fetch_club_members_by_cid(cid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_fetch_club_members = [[
        SELECT
            `cid`,
            `uid`,
            `club_chip`,
            `status`,
            `unread_amount`,
            `remind`
        FROM
            `club_members`
        WHERE
            `cid`=%d and `status`!=%d;
    ]]
    local command_fetch_club_members = string.format(
        command_fetch_club_members,
        cid, status
    )
    local res = mysql_obj:query(command_fetch_club_members)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            cid = tmp.cid,
            uid = tmp.uid,
            club_chip = tmp.club_chip,
            status = tmp.status,
            unread_amount = tmp.unread_amount,
            remind = tmp.remind
        })
    end
    return results_list
end

function root:fetch_club_members_by_cid_page(cid, offset_id, amount)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local tmp_command_fetch_club_members = [[
        SELECT
            `id`,
            `cid`,
            `uid`,
            `club_chip`,
            `status`,
            `unread_amount`
        FROM
            `club_members`
        WHERE
            `cid`=%d and `status`!=%d %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]

    local command_fetch_club_members = nil
    if offset_id <= 0 then
        command_fetch_club_members = string.format(
            tmp_command_fetch_club_members,
            cid, status, "", amount
        )
    else
        command_fetch_club_members = string.format(
            tmp_command_fetch_club_members,
            cid, status, "and id<" .. offset_id, amount
        )
    end

    local res = mysql_obj:query(command_fetch_club_members)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id,
            cid = tmp.cid,
            uid = tmp.uid,
            club_chip = tmp.club_chip,
            status = tmp.status,
            unread_amount = tmp.unread_amount
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:fetch_club_list_by_uid(uid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_fetch_club_list_by_uid = [[
        SELECT
            `cm`.`cid`,
            `cm`.`status`,
            `gc`.`club_name`,
            `gc`.`announcement`
        FROM
            `club_members` `cm`
        INNER JOIN
            `game_clubs` `gc`
        ON
            `cm`.`cid`=`gc`.cid
        WHERE
            `cm`.`uid`=%d and `cm`.`status`!=%d;
    ]]
    local command_fetch_club_list_by_uid = string.format(
        command_fetch_club_list_by_uid,
        uid, status
    )
    local res = mysql_obj:query(command_fetch_club_list_by_uid)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            cid = tmp.cid,
            club_name = tmp.club_name,
            announcement = tmp.announcement,
            status = tmp.status
        })
    end
    return results_list
end

function root:fetch_club_members_by_uid(uid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_fetch_club_members = [[
        SELECT
            `cid`,
            `uid`,
            `club_chip`,
            `status`,
            `unread_amount`,
            `remind`
        FROM
            `club_members`
        WHERE
            `uid`=%d and `status`!=%d;
    ]]
    local command_fetch_club_members = string.format(
        command_fetch_club_members,
        uid, status
    )
    local res = mysql_obj:query(command_fetch_club_members)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            cid = tmp.cid,
            uid = tmp.uid,
            club_chip = tmp.club_chip,
            status = tmp.status,
            unread_amount = tmp.unread_amount,
            remind = tmp.remind
        })
    end
    return results_list
end

function root:fetch_club_member(cid, uid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_fetch_club_member = [[
        SELECT
            `cid`,
            `uid`,
            `club_chip`,
            `status`
        FROM
            `club_members`
        WHERE
            `cid`=%d and `uid`=%d and `status`!=%d
        LIMIT 1;
    ]]
    local command_fetch_club_member = string.format(
        command_fetch_club_member,
        cid, uid, status
    )
    local res = mysql_obj:query(command_fetch_club_member)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.cid = tmp.cid
        results.uid = tmp.uid
        results.club_chip = tmp.club_chip
        results.status = tmp.status
    end
    return results
end

function root:fetch_club_applys_cid_status(cid, status)
    local command_fetch_club_applys_cid_status = [[
        SELECT
            `uid`,
            `cid`,
            `status`
        FROM
            `club_applys`
        WHERE
            `cid`=%d and `status`=%d;
    ]]
    local command_fetch_club_applys_cid_status = string.format(
        command_fetch_club_applys_cid_status,
        cid, status
    )
    local res = mysql_obj:query(command_fetch_club_applys_cid_status)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            uid = tmp.uid,
            cid = tmp.cid,
            status = tmp.status
        })
    end
    return results_list
end

function root:fetch_club_applys_cid(cid_list, offset_id, amount)
    local tmp_command_fetch_club_applys_cid = [[
        SELECT
            `id`,
            `uid`,
            `cid`,
            `status`
        FROM
            `club_applys`
        WHERE
            %s %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]
    local cid_cond_str = ""
    for k, v in ipairs(cid_list) do
        cid_cond_str = string.format("%s%s%s=%d", cid_cond_str, k == 1 and "" or " or ", "`cid`", v)
    end
    local command_fetch_club_applys_cid = nil
    if offset_id <= 0 then
        command_fetch_club_applys_cid = string.format(
            tmp_command_fetch_club_applys_cid,
            "(" .. cid_cond_str .. ")", "", amount
        )
    else
        command_fetch_club_applys_cid = string.format(
            tmp_command_fetch_club_applys_cid,
            "(" .. cid_cond_str .. ")", "and id<" .. offset_id, amount
        )
    end
    local res = mysql_obj:query(command_fetch_club_applys_cid)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id,
            uid = tmp.uid,
            cid = tmp.cid,
            status = tmp.status
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:update_club_apply_status(cid, uid, status)
    local command_update_club_apply_status = [[
        UPDATE
            `club_applys`
        SET
            `status`=%d
        WHERE
            `cid`=%d and `uid`=%d and `status`=%d
        LIMIT 1;
    ]]
    local command_update_club_apply_status = string.format(
        command_update_club_apply_status,
        status, cid, uid, common_conf.CLUB_APPLY_STATUS_WAIT
    )
    mysql_obj:query(command_update_club_apply_status)
end

function root:update_club_member_status(status, cid, uid)
    local command_update_club_member_status = [[
        UPDATE
            `club_members`
        SET
            `status`=%d
        WHERE
            `cid`=%d and `uid`=%d
        LIMIT 1;
    ]]
    local command_update_club_member_status = string.format(
        command_update_club_member_status,
        status, cid, uid
    )
    mysql_obj:query(command_update_club_member_status)
end

function root:update_club_member_club_chip(club_chip, cid, uid)
    local command_update_club_member_club_chip = [[
        UPDATE
            `club_members`
        SET
            `club_chip`=%d
        WHERE
            `cid`=%d and `uid`=%d
        LIMIT 1;
    ]]
    local command_update_club_member_club_chip = string.format(
        command_update_club_member_club_chip,
        club_chip, cid, uid
    )
    mysql_obj:query(command_update_club_member_club_chip)
end

function root:increase_club_member_club_chip(club_chip, cid, uid)
    local command_increase_club_member_club_chip = [[
        UPDATE
            `club_members`
        SET
            `club_chip`=`club_chip`+%d
        WHERE
            `cid`=%d and `uid`=%d
        LIMIT 1;
    ]]
    local command_increase_club_member_club_chip = string.format(
        command_increase_club_member_club_chip,
        club_chip, cid, uid
    )
    mysql_obj:query(command_increase_club_member_club_chip)
end

function root:delete_game_club(cid)
    local command_delete_game_club = [[
        DELETE FROM
            `game_clubs`
        WHERE
            `cid`=%d
        LIMIT 1;
    ]]
    local command_delete_game_club = string.format(command_delete_game_club, cid)
    mysql_obj:query(command_delete_game_club)
end

function root:delete_club_members(cid)
    local command_delete_club_members = [[
        DELETE FROM
            `club_members`
        WHERE
            `cid`=%d;
    ]]
    local command_delete_club_members = string.format(command_delete_club_members, cid)
    mysql_obj:query(command_delete_club_members)
end

function root:delete_club_applys(cid)
    local command_delete_club_applys = [[
        DELETE FROM
            `club_applys`
        WHERE
            `cid`=%d;
    ]]
    local command_delete_club_applys = string.format(command_delete_club_applys, cid)
    mysql_obj:query(command_delete_club_applys)
end

function root:insert_club_applys(uid, cid, status)
    local command_insert_club_applys = [[
        INSERT INTO `club_applys`(
            `uid`, `cid`, `status`
        ) VALUES(
            %d, %d, %d
        );
    ]]
    local command_insert_club_applys = string.format(
        command_insert_club_applys,
        uid, cid, status
    )
    mysql_obj:query(command_insert_club_applys)
end

function root:delete_club_chats(cid)
    local command_delete_club_chats = [[
        DELETE FROM
            `club_chats`
        WHERE
            `cid`=%d;
    ]]
    local command_delete_club_chats = string.format(command_delete_club_chats, cid)
    mysql_obj:query(command_delete_club_chats)
end

function root:is_exist_game_club(cid)
    local command_is_exist_game_club = [[
        SELECT IFNULL( (SELECT 'Y' FROM `game_clubs` WHERE `cid`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_game_club = string.format(command_is_exist_game_club, cid)
    local res = mysql_obj:query(command_is_exist_game_club)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_club_member(cid, uid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_is_exist_club_member = [[
        SELECT IFNULL( (SELECT 'Y' FROM `club_members` WHERE `cid`=%d and `uid`=%d and `status`!=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_club_member = string.format(command_is_exist_club_member, cid, uid, status)
    local res = mysql_obj:query(command_is_exist_club_member)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_old_club_member(cid, uid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_is_exist_club_member = [[
        SELECT IFNULL( (SELECT 'Y' FROM `club_members` WHERE `cid`=%d and `uid`=%d and `status`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_club_member = string.format(command_is_exist_club_member, cid, uid, status)
    local res = mysql_obj:query(command_is_exist_club_member)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_club_apply(cid, uid, status)
    local command_is_exist_club_apply = [[
        SELECT IFNULL( (SELECT 'Y' FROM `club_applys` WHERE `cid`=%d and `uid`=%d and `status`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_club_apply = string.format(command_is_exist_club_apply, cid, uid, status)
    local res = mysql_obj:query(command_is_exist_club_apply)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:insert_club_chats(cid, uid, type, content, time)
    local command_insert_club_chats = [[
        INSERT INTO `club_chats`(
            `cid`, `uid`, `type`, `content`, `time`
        ) VALUES(
            %d, %d, %d, '%s', %d
        );
    ]]
    local command_insert_club_chats = string.format(
        command_insert_club_chats,
        cid, uid, type, content, time
    )
    mysql_obj:query(command_insert_club_chats)
end

function root:fetch_club_chats(cid, offset_id, amount)
    local tmp_command_fetch_club_chats = [[
        SELECT
            `id`, `cid`, `uid`, `type`, `content`,
            `time`
        FROM
            `club_chats`
        WHERE
            `cid`=%d %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]
    local command_fetch_club_chats = nil
    if offset_id <= 0 then
        command_fetch_club_chats = string.format(
            tmp_command_fetch_club_chats,
            cid, "", amount
        )
    else
        command_fetch_club_chats = string.format(
            tmp_command_fetch_club_chats,
            cid, "and id<" .. offset_id, amount
        )
    end
    local res = mysql_obj:query(command_fetch_club_chats)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id, cid = tmp.cid, uid = tmp.uid, type = tmp.type, content = tmp.content,
            time = tmp.time
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:fetch_club_chats_newest(cid)
    local command_fetch_club_chats_newest = [[
        SELECT
            `id`, `cid`, `uid`, `type`, `content`,
            `time`
        FROM
            `club_chats`
        WHERE
            `cid`=%d
        ORDER BY
            `id`
        DESC LIMIT 1;
    ]]
    local command_fetch_club_chats_newest = string.format(
        command_fetch_club_chats_newest,
        cid
    )
    local res = mysql_obj:query(command_fetch_club_chats_newest)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id, cid = tmp.cid, uid = tmp.uid, type = tmp.type, content = tmp.content,
            time = tmp.time
        })
    end
    return results_list
end

function root:fetch_club_chats_newest_time(cid)
    local club_chat_list = self:fetch_club_chats_newest(cid)
    local time = 0
    for k, v in ipairs(club_chat_list) do
        time = v.time
    end
    return time
end

function root:curtail_club_chats(cid)
    local command_fetch_amount = [[
        SELECT
            COUNT(1) `amount`
        FROM
            `club_chats`
        WHERE
            `cid`=%d;
    ]]
    local command_curtail_data_by_amount = [[
        DELETE FROM
            `club_chats`
        WHERE
            `cid`=%d
        ORDER BY `id` ASC limit %d;
    ]]
    local command_curtail_data_by_time = [[
        DELETE FROM
            `club_chats`
        WHERE
            `time`<%d;
    ]]

    local current_time = skynet_time()
    local offset = current_time - common_conf.CHAT_LIST_LIFE_CYCLE_TIME
    local command_curtail_data_by_time = string.format(command_curtail_data_by_time, offset)
    mysql_obj:query(command_curtail_data_by_time)

    local command_fetch_amount = string.format(command_fetch_amount, cid)
    local res = mysql_obj:query(command_fetch_amount)
    local amount = 0
    while next(res) do
        local tmp = table.remove(res)
        amount = tmp.amount
    end
    local offset = amount - common_conf.CLUB_CHAT_AMOUNT_LIMIT
    if offset > 0  then
        local command_curtail_data_by_amount = string.format(command_curtail_data_by_amount, cid, offset)
        mysql_obj:query(command_curtail_data_by_amount)
    end
end

function root:reset_club_chats_unread_amount(cid, uid)
    local command_reset_club_chats_unread_amount = [[
        UPDATE
            `club_members`
        SET
            `unread_amount`=0
        WHERE
            `cid`=%d and `uid`=%d;
    ]]
    local command_reset_club_chats_unread_amount = string.format(
        command_reset_club_chats_unread_amount, cid, uid
    )
    mysql_obj:query(command_reset_club_chats_unread_amount)
end

function root:update_club_chats_remind(cid, uid, remind)
    local command_update_club_chats_remind = [[
        UPDATE
            `club_members`
        SET
            `remind`=%d
        WHERE
            `cid`=%d and `uid`=%d;
    ]]
    local command_update_club_chats_remind = string.format(
        command_update_club_chats_remind,
        remind, cid, uid
    )
    mysql_obj:query(command_update_club_chats_remind)
end

function root:increase_club_chats_unread_amount(cid, uid, amount)
    local command_increase_club_chats_unread_amount = [[
        UPDATE
            `club_members`
        SET
            `unread_amount`=`unread_amount`+%d
        WHERE
            `cid`=%d and `uid`=%d;
    ]]
    local command_increase_club_chats_unread_amount = string.format(
        command_increase_club_chats_unread_amount, amount, cid, uid
    )
    mysql_obj:query(command_increase_club_chats_unread_amount)
end

function root:fetch_club_list_by_config_cid(cid_cond_list)
    local results_list = {}
    if #cid_cond_list <= 0 then
        return results_list
    end
    local command_fetch_club_list_by_config_cid = [[
        SELECT
            `cm`.`cid`, `gc`.`club_name`, `gc`.`announcement`, `cm`.`uid`, `gu`.`nick_name`,
            `gu`.`avatar`, 0 `total_expend_room_card`
        FROM
            `game_clubs` `gc`
        INNER JOIN
            `club_members` `cm`
        ON
            `gc`.`cid`=`cm`.`cid`
        INNER JOIN
            `game_users` `gu`
        ON
            `cm`.`uid`=`gu`.`uid`
        WHERE
            `cm`.`status`=3
        AND
            `gc`.`cid`>0
        AND
            (%s);
    ]]
    local cid_cond_str = ""
    for k, v in ipairs(cid_cond_list) do 
        cid_cond_str = string.format("%s%s%s=%d", cid_cond_str, k == 1 and "" or " or ", "`gc`.`cid`", v.cid)
    end
    command_fetch_club_list_by_config_cid = string.format(command_fetch_club_list_by_config_cid, cid_cond_str)
    local res = mysql_obj:query(command_fetch_club_list_by_config_cid)
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            cid = tmp.cid,
            club_name = tmp.club_name,
            announcement = tmp.announcement,
            owner_uid = tmp.uid,
            owner_avatar = tmp.avatar,
            owner_nick_name = tmp.nick_name,
            total_expend_room_card = tmp.total_expend_room_card
        })
    end
    return results_list
end

function root:fetch_club_list_by_expend_room_card_rank()
    local command_fetch_club_list_by_expend_room_card_rank = [[
        SELECT
            `rr`.`cid`, `gc`.`club_name`, `gc`.`announcement`, `cm`.`uid`, `gu`.`nick_name`,
            `gu`.`avatar`, SUM(`rr`.`expend_room_card`) `total_expend_room_card`
        FROM
            `room_records` `rr`
        INNER JOIN
            `game_clubs` `gc`
        ON
            `rr`.`cid`=`gc`.`cid`
        INNER JOIN
            `club_members` `cm`
        ON
            `gc`.`cid`=`cm`.`cid`
        INNER JOIN
            `game_users` `gu`
        ON
            `cm`.`uid`=`gu`.`uid`
        WHERE
            `cm`.`status`=%d
        AND
            `gc`.`join_rank`=%d
        AND
            `rr`.`cid`>0
        AND
            (TO_DAYS(NOW())-TO_DAYS(`rr`.`create_date`))<=%d
        AND
            `rr`.`expend`=%d
        GROUP BY
            `rr`.`cid`
        ORDER BY
            `total_expend_room_card`
        DESC LIMIT 0, %d;
    ]]
    local command_fetch_club_list_by_expend_room_card_rank = string.format(
        command_fetch_club_list_by_expend_room_card_rank, common_conf.CLUB_MEMBER_STATUS_OWNER,
        common_conf.CLUB_JOIN_RANK, common_conf.CLUB_RANK_DAY_BASE, common_conf.EXPENDED, common_conf.CLUB_RANK_AMOUNT
    )
    local res = mysql_obj:query(command_fetch_club_list_by_expend_room_card_rank)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            cid = tmp.cid,
            club_name = tmp.club_name,
            announcement = tmp.announcement,
            owner_uid = tmp.uid,
            owner_avatar = tmp.avatar,
            owner_nick_name = tmp.nick_name,
            total_expend_room_card = tmp.total_expend_room_card
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.total_expend_room_card > v2.total_expend_room_card
    end)
    return results_list
end

function root:fetch_club_members_by_cid_optimize(cid)
    local status = common_conf.CLUB_MEMBER_STATUS_LEAVE
    local command_fetch_club_members = [[
        SELECT
            `cm`.`uid`,
            `cm`.`club_chip`,
            `cm`.`status`,
            `gu`.`nick_name`,
            `gu`.`avatar`
        FROM
            `club_members` `cm`
        INNER JOIN
            `game_users` `gu`
        ON
            `cm`.`uid`=`gu`.uid
        WHERE
            `cm`.`cid`=%d and `cm`.`status`!=%d;
    ]]
    local command_fetch_club_members = string.format(
        command_fetch_club_members,
        cid, status
    )
    local res = mysql_obj:query(command_fetch_club_members)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            uid = tmp.uid,
            club_chip = tmp.club_chip,
            status = tmp.status,
            nick_name = tmp.nick_name,
            avatar = tmp.avatar
        })
    end
    return results_list
end

return root