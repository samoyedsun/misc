local skynet = require "skynet"
local rpc_mysql = require "rpc_mysql"
local mysql_obj = rpc_mysql.get_mysql("zhongyouhui")
local common_db = require "server.common.common_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_common_game_rooms_db")

local root = {}

function root:insert_game_rooms(param)
    local command_insert_game_rooms = [[
        INSERT INTO game_rooms(
            `owner_uid`, `round_limit`, `user_limit`, `game_mode`, `bet_slot_limit`,
            `carry_score`, `banker_uid`, `game_type`, `big_game_mode`, `cid`,
            `room_number`, `rid`, `skynet_service_id`, `status`, `round_amount`,
            `user_amount`
        ) VALUES(
            %d, %d, %d, %d, %d,
            %d, %d, %d, %d, %d,
            '%s', %d, %d, %d, %d,
            %d
        )
    ]]
    local command_insert_game_rooms = string.format(command_insert_game_rooms,
        param.owner_uid, param.round_limit, param.user_limit, param.game_mode, param.bet_slot_limit,
        param.carry_score, param.banker_uid, param.game_type, param.big_game_mode, param.cid,
        param.room_number, param.rid, param.skynet_service_id, param.status, param.round_amount,
        param.user_amount
    )
    mysql_obj:query(command_insert_game_rooms)
end

function root:delete_game_rooms(rid)
    local command_delete_game_rooms = [[
        DELETE FROM
            `game_rooms`
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_delete_game_rooms = string.format(command_delete_game_rooms, rid)
    mysql_obj:query(command_delete_game_rooms)
end

function root:fetch_skynet_service_id_list()
    local command_fetch_skynet_service_id_list = [[
        SELECT
            `rid`, `skynet_service_id`
        FROM
            `game_rooms`;
    ]]
    local res = mysql_obj:query(command_fetch_skynet_service_id_list)
    local result_list = {}
    while next(res) do 
        local tmp = table.remove(res)
        table.insert(result_list, tmp.skynet_service_id)
    end
    return result_list
end

function root:is_exist_game_room_by_room_number(room_number)
    local command_is_exist_game_room_by_room_number = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_rooms` WHERE `room_number`='%s' LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_game_room_by_room_number = string.format(command_is_exist_game_room_by_room_number, room_number)
    local res = mysql_obj:query(command_is_exist_game_room_by_room_number)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_game_room_by_rid(rid)
    local command_is_exist_game_room_by_rid = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_rooms` WHERE `rid`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_game_room_by_rid = string.format(command_is_exist_game_room_by_rid, rid)
    local res = mysql_obj:query(command_is_exist_game_room_by_rid)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_game_room_by_cid(cid)
    local command_is_exist_game_room_by_cid = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `game_rooms` WHERE `cid`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_game_room_by_cid = string.format(command_is_exist_game_room_by_cid, cid)
    local res = mysql_obj:query(command_is_exist_game_room_by_cid)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:update_game_room_banker_uid_by_rid(rid, banker_uid)
    local command_update_game_room_banker_uid_by_rid = [[
        UPDATE
            `game_rooms`
        SET
            `banker_uid`=%d
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_update_game_room_banker_uid_by_rid = string.format(
        command_update_game_room_banker_uid_by_rid,
        banker_uid, rid)
    mysql_obj:query(command_update_game_room_banker_uid_by_rid)
end

function root:update_game_room_status_by_rid(rid, status)
    local command_update_game_room_status_by_rid = [[
        UPDATE
            `game_rooms`
        SET
            `status`=%d
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_update_game_room_status_by_rid = string.format(
            command_update_game_room_status_by_rid,
            status, rid)
    mysql_obj:query(command_update_game_room_status_by_rid)
end

function root:update_game_room_round_amount_by_rid(rid, round_amount)
    local command_update_game_room_round_amount_by_rid = [[
        UPDATE
            `game_rooms`
        SET
            `round_amount`=%d
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_update_game_room_round_amount_by_rid = string.format(
            command_update_game_room_round_amount_by_rid,
            round_amount, rid)
    mysql_obj:query(command_update_game_room_round_amount_by_rid)
end

function root:update_game_room_user_amount_by_rid(rid, user_amount)
    local command_update_game_room_user_amount_by_rid = [[
        UPDATE
            `game_rooms`
        SET
            `user_amount`=%d
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_update_game_room_user_amount_by_rid = string.format(
            command_update_game_room_user_amount_by_rid,
            user_amount, rid)
    mysql_obj:query(command_update_game_room_user_amount_by_rid)
end

function root:fetch_game_room_by_room_number(room_number)
    local command_fetch_game_room_by_room_number = [[
        SELECT
            `owner_uid`, `round_limit`, `user_limit`, `game_mode`, `bet_slot_limit`,
            `carry_score`, `banker_uid`, `game_type`, `big_game_mode`, `cid`,
            `room_number`, `rid`, `skynet_service_id`, `status`, `round_amount`,
            `user_amount`
        FROM
            `game_rooms`
        WHERE
            `room_number`='%s'
        LIMIT 1;
    ]]
    local command_fetch_game_room_by_room_number = string.format(command_fetch_game_room_by_room_number, room_number)
    local res = mysql_obj:query(command_fetch_game_room_by_room_number)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.owner_uid = tmp.owner_uid
        results.round_limit = tmp.round_limit
        results.user_limit = tmp.user_limit
        results.game_mode = tmp.game_mode
        results.bet_slot_limit = tmp.bet_slot_limit
        results.carry_score = tmp.carry_score
        results.banker_uid = tmp.banker_uid
        results.game_type = tmp.game_type
        results.big_game_mode = tmp.big_game_mode
        results.cid = tmp.cid
        results.room_number = tmp.room_number
        results.rid = tmp.rid
        results.skynet_service_id = tmp.skynet_service_id
        results.status = tmp.status
        results.round_amount = tmp.round_amount
        results.user_amount = tmp.user_amount
    end
    return results
end

function root:fetch_game_room_by_rid(rid)
    local command_fetch_game_room_by_rid = [[
        SELECT
            `owner_uid`, `round_limit`, `user_limit`, `game_mode`, `bet_slot_limit`,
            `carry_score`, `banker_uid`, `game_type`, `big_game_mode`, `cid`,
            `room_number`, `rid`, `skynet_service_id`, `status`, `round_amount`,
            `user_amount`
        FROM
            `game_rooms`
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_fetch_game_room_by_rid = string.format(command_fetch_game_room_by_rid, rid)
    local res = mysql_obj:query(command_fetch_game_room_by_rid)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.owner_uid = tmp.owner_uid
        results.round_limit = tmp.round_limit
        results.user_limit = tmp.user_limit
        results.game_mode = tmp.game_mode
        results.bet_slot_limit = tmp.bet_slot_limit
        results.carry_score = tmp.carry_score
        results.banker_uid = tmp.banker_uid
        results.game_type = tmp.game_type
        results.big_game_mode = tmp.big_game_mode
        results.cid = tmp.cid
        results.room_number = tmp.room_number
        results.rid = tmp.rid
        results.skynet_service_id = tmp.skynet_service_id
        results.status = tmp.status
        results.round_amount = tmp.round_amount
        results.user_amount = tmp.user_amount
    end
    return results
end

function root:fetch_game_room_amount(cid)
    local command_fetch_game_room_amount = [[
        SELECT
            COUNT(1) `amount`
        FROM
            `game_rooms`
        WHERE
            `cid`=%d;
    ]]
    local command_fetch_game_room_amount = string.format(command_fetch_game_room_amount, cid)
    local res = mysql_obj:query(command_fetch_game_room_amount)
    local amount = 0
    while next(res) do
        local tmp = table.remove(res)
        amount = tmp.amount
    end
    return amount
end

function root:fetch_game_rooms_by_cid(cid)
    local command_fetch_game_rooms_by_cid = [[
        SELECT
            `gr`.`owner_uid`, `gr`.`round_limit`, `gr`.`user_limit`, `gr`.`game_mode`, `gr`.`bet_slot_limit`,
            `gr`.`carry_score`, `gr`.`banker_uid`, `gr`.`game_type`, `gr`.`big_game_mode`, `gr`.`cid`,
            `gr`.`room_number`, `gr`.`rid`, `gr`.`skynet_service_id`, `gr`.`status`, `gr`.`round_amount`,
            `gr`.`user_amount`, `gu`.`avatar` `owner_avatar`
        FROM
            `game_rooms` `gr`
        INNER JOIN
            `game_users` `gu`
        ON
            `gr`.`owner_uid`=`gu`.`uid`
        WHERE
            `gr`.`cid`=%d;
    ]]
    local command_fetch_game_rooms_by_cid = string.format(command_fetch_game_rooms_by_cid, cid)
    local res = mysql_obj:query(command_fetch_game_rooms_by_cid)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            owner_uid = tmp.owner_uid,
            round_limit = tmp.round_limit,
            user_limit = tmp.user_limit,
            game_mode = tmp.game_mode,
            bet_slot_limit = tmp.bet_slot_limit,
            carry_score = tmp.carry_score,
            banker_uid = tmp.banker_uid,
            game_type = tmp.game_type,
            big_game_mode = tmp.big_game_mode,
            cid = tmp.cid,
            room_number = tmp.room_number,
            rid = tmp.rid,
            skynet_service_id = tmp.skynet_service_id,
            status = tmp.status,
            round_amount = tmp.round_amount,
            user_amount = tmp.user_amount,
            owner_avatar = tmp.owner_avatar
        })
    end
    return results_list
end

return root