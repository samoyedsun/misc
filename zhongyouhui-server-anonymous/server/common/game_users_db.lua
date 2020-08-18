local skynet = require "skynet"
local rpc_mysql = require "rpc_mysql"
local mysql_obj = rpc_mysql.get_mysql("zhongyouhui")
local common_db = require "server.common.common_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_common_game_users_db")

local root = {}

function root:is_exist_game_user_by_uid(uid)
    local command_is_exist_game_user = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_users` WHERE `uid` = %d LIMIT 1 ), 'N' ) is_exist;
    ]]
    local command_is_exist_game_user = string.format(command_is_exist_game_user, uid)
    local res = mysql_obj:query(command_is_exist_game_user)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end


function root:is_exist_game_user_by_unionid(unionid)
    local command_is_exist_game_user = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_users` WHERE `unionid` = '%s' LIMIT 1 ), 'N' ) is_exist;
    ]]
    local command_is_exist_game_user = string.format(command_is_exist_game_user, unionid)
    local res = mysql_obj:query(command_is_exist_game_user)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_game_user_by_phone_number(phone_number)
    local command_is_exist_game_user = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_users` WHERE `phone_number` = '%s' LIMIT 1 ), 'N' ) is_exist;
    ]]
    local command_is_exist_game_user = string.format(command_is_exist_game_user, phone_number)
    local res = mysql_obj:query(command_is_exist_game_user)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_game_user_invite_code(uid)
    local command_is_exist_game_user = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_users` WHERE uid = %d and `invite_code` != 0 LIMIT 1 ), 'N' ) is_exist;
    ]]
    local command_is_exist_game_user = string.format(command_is_exist_game_user, uid)
    local res = mysql_obj:query(command_is_exist_game_user)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:insert_game_users(param)
    local command_insert_game_users = [[
        INSERT INTO `game_users`(
            `uid`, `avatar`, `nick_name`, `gold_coin`, `diamond`,
            `room_card`, `gender`, `sound`, `music`, `rid`,
            `agency`, `language`, `city`, `province`, `country`,
            `privilege`, `unionid`
        ) VALUES(
            %d, '%s', '%s', %d, %d,
            %d, %d, %d, %d, %d,
            %d, '%s', '%s', '%s', '%s',
            '%s', '%s'
        );
    ]]
    param.nick_name = string.gsub(param.nick_name, "'", "''");
    local command_insert_game_users = string.format(command_insert_game_users,
        param.uid, param.avatar, param.nick_name, param.gold_coin, param.diamond,
        param.room_card, param.gender, param.sound, param.music, param.rid,
        param.agency, param.language, param.city, param.province, param.country,
        param.privilege, param.unionid
    )
    mysql_obj:query(command_insert_game_users)
end

function root:fetch_game_user_agency(uid)
    local command_fetch_game_user_agency = [[
        SELECT
            agency
        FROM
            game_users
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_fetch_game_user_agency = string.format(command_fetch_game_user_agency, uid)
    local res = mysql_obj:query(command_fetch_game_user_agency)
    local agency = common_conf.NOT_AGENCY
    while next(res) do
        local tmp = table.remove(res)
        agency = tmp.agency
    end
    return agency
end

function root:update_game_user_agency(uid, agency)
    local command_update_game_user_agency = [[
        UPDATE
            `game_users`
        SET
            `agency`=%d
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_update_game_user_agency = string.format(
        command_update_game_user_agency,
        agency, uid
    )
    mysql_obj:query(command_update_game_user_agency)
end

function root:update_game_user_info_by_unionid(unionid, param)
    local command_update_game_user_info_by_unionid = [[
        UPDATE
            game_users
        SET
            avatar='%s', nick_name='%s', gender=%d, language='%s', city='%s',
            province='%s', country='%s', privilege='%s'
        WHERE
            unionid='%s'
        LIMIT 1;
    ]]
    param.nick_name = string.gsub(param.nick_name, "'", "''");
    local command_update_game_user_info_by_unionid = string.format(
        command_update_game_user_info_by_unionid,
        param.avatar, param.nick_name, param.gender, param.language, param.city,
        param.province, param.country, param.privilege,
        unionid)
    mysql_obj:query(command_update_game_user_info_by_unionid)
end

function root:update_game_user_online(uid, online)
    local command_update_game_user_online = [[
        UPDATE
            `game_users`
        SET
            `online`=%d
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_update_game_user_online = string.format(command_update_game_user_online, online, uid)
    mysql_obj:query(command_update_game_user_online)
end

function root:clear_game_user_rid(rid)
    local command_clear_game_user_rid = [[
        UPDATE
            game_users
        SET
            rid=%d
        WHERE
            rid=%d;
    ]]
    local command_clear_game_user_rid = string.format(command_clear_game_user_rid, common_conf.NOT_IN_ROOM, rid)
    mysql_obj:query(command_clear_game_user_rid)
end

function root:update_game_user_rid(uid, rid)
    local command_update_game_user_rid = [[
        UPDATE
            game_users
        SET
            rid=%d
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_update_game_user_rid = string.format(command_update_game_user_rid, rid, uid)
    mysql_obj:query(command_update_game_user_rid)
end

function root:fetch_game_user_rid(uid)
    local command_fetch_game_user_rid = [[
        SELECT
            rid
        FROM
            game_users
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_fetch_game_user_rid = string.format(command_fetch_game_user_rid, uid)
    local res = mysql_obj:query(command_fetch_game_user_rid)
    local rid = 0
    while next(res) do 
        local tmp = table.remove(res)
        rid = tmp.rid
    end
    return rid
end

function root:increase_game_user_room_card(room_card, uid)
    local command_increase_game_user_room_card = [[
        UPDATE
            game_users
        SET
            room_card=room_card+%d
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_increase_game_user_room_card = string.format(command_increase_game_user_room_card, room_card, uid)
    mysql_obj:query(command_increase_game_user_room_card)
end

function root:increase_game_user_diamond(diamond, uid)
    local command_increase_game_user_diamond = [[
        UPDATE
            game_users
        SET
            diamond=diamond+%d
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_increase_game_user_diamond = string.format(command_increase_game_user_diamond, diamond, uid)
    mysql_obj:query(command_increase_game_user_diamond)
end

function root:increase_game_user_gold_coin(gold_coin, uid)
    local command_increase_game_user_gold_coin = [[
        UPDATE
            game_users
        SET
            gold_coin=gold_coin+%d
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_increase_game_user_gold_coin = string.format(command_increase_game_user_gold_coin, gold_coin, uid)
    mysql_obj:query(command_increase_game_user_gold_coin)
end

function root:fetch_game_user_by_uid(uid)
    local command_fetch_game_user_by_uid = [[
        SELECT
            `uid`, `avatar`, `nick_name`, `gold_coin`, `diamond`,
            `room_card`, `gender`, `phone_number`, `discount`, `invite_code`,
            `online`, `rid`
        FROM
            `game_users`
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_fetch_game_user_by_uid = string.format(command_fetch_game_user_by_uid, uid)
    local res = mysql_obj:query(command_fetch_game_user_by_uid)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.uid = tmp.uid
        results.avatar = tmp.avatar
        results.nick_name = tmp.nick_name
        results.gold_coin = tmp.gold_coin
        results.diamond = tmp.diamond
        results.room_card = tmp.room_card
        results.gender = tmp.gender
        results.phone_number = tmp.phone_number
        results.discount = tmp.discount
        results.invite_code = tmp.invite_code
        results.online = tmp.online
        results.rid = tmp.rid
    end
    return results
end

function root:fetch_game_user_uid_by_phone_number(phone_number)
    local command_fetch_game_user_uid_by_phone_number = [[
        SELECT
            `uid`
        FROM
            `game_users`
        WHERE
            `phone_number`='%s'
        LIMIT 1;
    ]]
    local command_fetch_game_user_uid_by_phone_number = string.format(command_fetch_game_user_uid_by_phone_number, phone_number)
    local res = mysql_obj:query(command_fetch_game_user_uid_by_phone_number)
    local uid = 0
    while next(res) do
        local tmp = table.remove(res)
        uid = tmp.uid
    end
    return uid
end

function root:fetch_game_user_uid_by_unionid(unionid)
    local command_fetch_game_user_uid_by_unionid = [[
        SELECT
            `uid`
        FROM
            `game_users`
        WHERE
            `unionid`='%s'
        LIMIT 1;
    ]]
    local command_fetch_game_user_uid_by_unionid = string.format(command_fetch_game_user_uid_by_unionid, unionid)
    local res = mysql_obj:query(command_fetch_game_user_uid_by_unionid)
    local uid = 0
    while next(res) do
        local tmp = table.remove(res)
        uid = tmp.uid
    end
    return uid
end

function root:fetch_game_user_unionid_by_uid(uid)
    local command_fetch_game_user_unionid_by_uid = [[
        SELECT
            `unionid`
        FROM
            `game_users`
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_fetch_game_user_unionid_by_uid = string.format(command_fetch_game_user_unionid_by_uid, uid)
    local res = mysql_obj:query(command_fetch_game_user_unionid_by_uid)
    local unionid = 0
    while next(res) do
        local tmp = table.remove(res)
        unionid = tmp.unionid
    end
    return unionid
end

function root:update_game_user_setting(uid, sound, music)
    local command_update_game_user_setting = [[
        UPDATE
            game_users
        SET
            sound=%d, music=%d
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_update_game_user_setting = string.format(command_update_game_user_setting, sound, music, uid)
    mysql_obj:query(command_update_game_user_setting)
end

function root:fetch_game_user_setting(uid)
    local command_fetch_game_user_setting = [[
        SELECT
            sound, music
        FROM
            game_users
        WHERE
            uid=%d
        LIMIT 1;
    ]]
    local command_fetch_game_user_setting = string.format(command_fetch_game_user_setting, uid)
    local res = mysql_obj:query(command_fetch_game_user_setting)
    local results = {}
    while next(res) do 
        local tmp = table.remove(res)
        results.sound = tmp.sound
        results.music = tmp.music
    end
    return results
end

function root:update_game_user_phone_number(uid, phone_number)
    local command_update_game_user_phone_number = [[
        UPDATE
            game_users
        SET
            phone_number='%s'
        WHERE
            uid=%d;
    ]]
    local command_update_game_user_phone_number = string.format(command_update_game_user_phone_number, phone_number, uid)
    mysql_obj:query(command_update_game_user_phone_number)
end

function root:update_game_user_invite_code(uid, invite_code)
    local command_update_game_user_invite_code = [[
        UPDATE
            game_users
        SET
            invite_code=%d,
            invite_code_time=%d
        WHERE
            uid=%d;
    ]]
    local current_time = skynet_time()
    local command_update_game_user_invite_code = string.format(
        command_update_game_user_invite_code,
        invite_code, current_time, uid
    )
    mysql_obj:query(command_update_game_user_invite_code)
end

return root
