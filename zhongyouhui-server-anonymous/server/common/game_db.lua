local skynet = require "skynet"
local rpc_mysql = require "rpc_mysql"
local mysql_obj = rpc_mysql.get_mysql("zhongyouhui")
local common_db = require "server.common.common_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_common_game_db")

local root = {}

function root:example_sql_execution(rid)
    local command = [[
        SELECT
            *
        FROM
            `room_numbers`
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command = string.format(command, rid)
    return mysql_obj:query(command)
end

function root:fetch_cid()
    local command_lock_cid_seed = "LOCK TABLES cid_seed WRITE;"
    local command_unlock_cid_seed = "UNLOCK TABLES;"

    local db = common_db:create_mysql_connect()
    common_db:query_by_mysql_connect(db, command_lock_cid_seed)
    local command_fetch_cid_seed = [[
        SELECT
            cid
        FROM
            cid_seed
        LIMIT 1;
    ]]
    local res = common_db:query_by_mysql_connect(db, command_fetch_cid_seed)
    local cid = common_conf.CID_SEED
    while next(res) do
        local tmp = table.remove(res)
        cid = tmp.cid
    end
    if cid == common_conf.CID_SEED then
        local command_init_cid_seed = [[
            INSERT INTO cid_seed(
                cid
            ) VALUES(
                %d
            );
        ]]
        local command_init_cid_seed = string.format(command_init_cid_seed, cid + 1)
        common_db:query_by_mysql_connect(db, command_init_cid_seed)
    else
        local command_increment_cid_seed = [[
            UPDATE 
                cid_seed
            SET
                cid=cid+1
            LIMIT 1;
        ]]
        common_db:query_by_mysql_connect(db, command_increment_cid_seed)
    end
    common_db:query_by_mysql_connect(db, command_unlock_cid_seed)
    common_db:close_mysql_connect(db)
    return cid
end

function root:fetch_rid()
    local command_lock_rid_seed = "LOCK TABLES rid_seed WRITE;"
    local command_unlock_rid_seed = "UNLOCK TABLES;"

    local db = common_db:create_mysql_connect()
    common_db:query_by_mysql_connect(db, command_lock_rid_seed)
    local command_fetch_rid_seed = [[
        SELECT
            rid
        FROM
            rid_seed
        LIMIT 1;
    ]]
    local res = common_db:query_by_mysql_connect(db, command_fetch_rid_seed)
    local rid = common_conf.RID_SEED
    while next(res) do
        local tmp = table.remove(res)
        rid = tmp.rid
    end
    if rid == common_conf.RID_SEED then
        local command_init_rid_seed = [[
            INSERT INTO rid_seed(
                rid
            ) VALUES(
                %d
            );
        ]]
        local command_init_rid_seed = string.format(command_init_rid_seed, rid + 1)
        common_db:query_by_mysql_connect(db, command_init_rid_seed)
    else
        local command_increment_rid_seed = [[
            UPDATE 
                rid_seed
            SET
                rid=rid+1
            LIMIT 1;
        ]]
        common_db:query_by_mysql_connect(db, command_increment_rid_seed)
    end
    common_db:query_by_mysql_connect(db, command_unlock_rid_seed)
    common_db:close_mysql_connect(db)
    return rid
end

function root:fetch_uid()
    local command_lock_uid_seed = "LOCK TABLES uid_seed WRITE;"
    local command_unlock_uid_seed = "UNLOCK TABLES;"

    local db = common_db:create_mysql_connect()
    common_db:query_by_mysql_connect(db, command_lock_uid_seed)
    local command_fetch_uid_seed = [[
        SELECT
            uid
        FROM
            uid_seed
        LIMIT 1;
    ]]
    local res = common_db:query_by_mysql_connect(db, command_fetch_uid_seed)
    local uid = common_conf.UID_SEED
    while next(res) do
        local tmp = table.remove(res)
        uid = tmp.uid
    end
    if uid == common_conf.UID_SEED then
        local command_init_uid_seed = [[
            INSERT INTO uid_seed(
                uid
            ) VALUES(
                %d
            );
        ]]
        local command_init_uid_seed = string.format(command_init_uid_seed, uid + 1)
        common_db:query_by_mysql_connect(db, command_init_uid_seed)
    else
        local command_increment_uid_seed = [[
            UPDATE 
                uid_seed
            SET
                uid=uid+1
            LIMIT 1;
        ]]
        common_db:query_by_mysql_connect(db, command_increment_uid_seed)
    end
    common_db:query_by_mysql_connect(db, command_unlock_uid_seed)
    common_db:close_mysql_connect(db)
    return uid
end

function root:fetch_room_number()
    local command_lock_room_numbers = "LOCK TABLES room_numbers WRITE;"
    local command_unlock_room_numbers = "UNLOCK TABLES;"
    local command_fetch_rand_base = [[
        SELECT
            FLOOR(RAND()*(MAX(id)-MIN(id)+MIN(id))) as rand_base
        FROM
            room_numbers
        LIMIT 1;
    ]]
    local command_fetch_one = [[
        SELECT
            *
        FROM
            room_numbers
        WHERE
            in_use=0 and id>=%d
        ORDER BY
            id
        LIMIT 1;
    ]]
    local command_update_in_use = [[
        UPDATE
            room_numbers
        SET
            in_use=1
        WHERE
            id=%d
        LIMIT 1;
    ]]
    local db = common_db:create_mysql_connect()
    common_db:query_by_mysql_connect(db, command_lock_room_numbers)
    local res = common_db:query_by_mysql_connect(db, command_fetch_rand_base)
    local rand_base = 0
    while next(res) do
        local tmp = table.remove(res)
        rand_base = tmp.rand_base
    end
    local command_fetch_one = string.format(command_fetch_one, rand_base)
    local res = common_db:query_by_mysql_connect(db, command_fetch_one)
    if #res == 0 then
        logger.error("fetch room num fail!")
        common_db:query_by_mysql_connect(db, command_unlock_room_numbers)
        common_db:close_mysql_connect(db)
        return false
    end
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.id = tmp.id
        results.room_number = tmp.room_number
        results.in_use = tmp.in_use
    end
    local command_update_one = string.format(command_update_in_use, results.id)
    db:query(command_update_one)
    common_db:query_by_mysql_connect(db, command_unlock_room_numbers)
    common_db:close_mysql_connect(db)
    return true, results.room_number
end

function root:attach_use_room_number_rid(room_number, rid)
    local command_attach_use_room_number_rid = [[
        UPDATE
            room_numbers
        SET
            rid=%d
        WHERE
            room_number='%s'
        LIMIT 1;
    ]]
    local command_attach_use_room_number_rid = string.format(command_attach_use_room_number_rid, rid, room_number)
    mysql_obj:query(command_attach_use_room_number_rid)
end

function root:resolve_use_room_number_rid(room_number)
    local command_update_in_use = [[
        UPDATE
            room_numbers
        SET
            in_use=0, rid=0
        WHERE
            room_number='%s'
        LIMIT 1;
    ]]
    local command_update_in_use = string.format(command_update_in_use, room_number)
    mysql_obj:query(command_update_in_use)
end

function root:is_exist_recharge_setting_by_type(type)
    local command_is_exist_recharge_setting_by_type = [[
        SELECT IFNULL( (SELECT 'Y' FROM `recharge_settings` WHERE `type`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_recharge_setting_by_type = string.format(command_is_exist_recharge_setting_by_type, type)
    local res = mysql_obj:query(command_is_exist_recharge_setting_by_type)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:fetch_recharge_settings_by_type(type)
    local command_fetch_recharge_settings_by_type = [[
        SELECT
            `id`, `type`, `price`, `buy`
        FROM
            `recharge_settings`
        WHERE
            `type` = %d and
            `show` = %d and
            `show_type` = %d;
    ]]
    local command_fetch_recharge_settings_by_type = string.format(
        command_fetch_recharge_settings_by_type,
        type, common_conf.RECHARGE_SHOW, common_conf.RECHARGE_SHOW_TYPE_MOBILE
    )
    local res = mysql_obj:query(command_fetch_recharge_settings_by_type)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id,
            type = tmp.type,
            price = tmp.price,
            buy = tmp.buy
        })
    end
    return results_list
end

function root:is_exist_recharge_setting_by_id(id)
    local command_is_exist_recharge_setting_by_id = [[
        SELECT IFNULL( (SELECT 'Y' FROM `recharge_settings` WHERE `id`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_recharge_setting_by_id = string.format(command_is_exist_recharge_setting_by_id, id)
    local res = mysql_obj:query(command_is_exist_recharge_setting_by_id)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:fetch_recharge_setting_by_id(id)
    local command_fetch_recharge_setting_by_id = [[
        SELECT
            id, type, price, buy
        FROM
            recharge_settings
        WHERE
            id = %d
        LIMIT 1;
    ]]
    local command_fetch_recharge_setting_by_id = string.format(command_fetch_recharge_setting_by_id, id)
    local res = mysql_obj:query(command_fetch_recharge_setting_by_id)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.id = tmp.id
        results.type = tmp.type
        results.price = tmp.price
        results.buy = tmp.buy
    end
    return results
end

function root:insert_user_room_records(uid, total_score, room_create_info, content)
    local command_insert_user_room_records = [[
        INSERT INTO user_room_records(
            uid, rid, content, room_number, expend_room_card,
            room_close_time, game_type, round_limit, user_limit, game_mode,
            bet_slot_limit, carry_score, bet_tao_switch, big_game_mode, cid,
            total_score
        ) VALUES(
            %d, %d, '%s', '%s', %d,
            %d, %d, %d, %d, %d,
            %d, %d, %d, %d, %d,
            %d
        );
    ]]
    local command_insert_user_room_records = string.format(command_insert_user_room_records,
        uid, room_create_info.rid, content, room_create_info.room_number, room_create_info.expend_room_card,
        room_create_info.room_close_time, room_create_info.game_type, room_create_info.round_limit, room_create_info.user_limit, room_create_info.game_mode,
        room_create_info.bet_slot_limit, room_create_info.carry_score, room_create_info.bet_tao_switch, room_create_info.big_game_mode, room_create_info.cid,
        total_score
    )
    mysql_obj:query(command_insert_user_room_records)
end

function root:patch_user_room_records()
    local command_update_user_room_records = [[
        UPDATE
            `user_room_records`
        SET
            `total_score` =%d
        WHERE `uid` =%d AND `rid` =%d;
    ]]
    local command_fetch_uid_list = [[
        SELECT
            `uid`,
            `rid`,
            `content`,
            `total_score`
        FROM
            `user_room_records`;
    ]]
    local res = mysql_obj:query(command_fetch_uid_list)
    while next(res) do
        local tmp = table.remove(res)
        local uid = tmp.uid
        local rid = tmp.rid
        local content = cjson_decode(tmp.content)
        local total_score = tmp.total_score
        for k, v in ipairs(content.total_score_info_list) do
            if v.uid == uid then
                total_score = v.total_score
            end
        end
        local command_update_user_room_records = string.format(command_update_user_room_records, total_score, uid, rid)
        local res = mysql_obj:query(command_update_user_room_records)
    end
end

function root:curtail_user_room_records(uid, cid)
    local command_fetch_amount = [[
        SELECT
            COUNT(1) `amount`
        FROM
            `user_room_records`
        WHERE
            `uid`=%d %s;
    ]]
    local command_curtail_data_by_amount = [[
        DELETE FROM
            `user_room_records`
        WHERE
            `uid`=%d %s
        ORDER BY `id` ASC limit %d;
    ]]
    local command_curtail_data_by_time = [[
        DELETE FROM
            `user_room_records`
        WHERE
            (%d-`room_close_time`)>%d
    ]]
    local cid_cond_str = ""
    if cid then
        cid_cond_str = " and `cid`=" .. cid
    end
    local command_fetch_amount = string.format(command_fetch_amount, uid, cid_cond_str)
    local res = mysql_obj:query(command_fetch_amount)
    local amount = 0
    while next(res) do
        local tmp = table.remove(res)
        amount = tmp.amount
    end
    local offset = amount - shake_dice_conf.ROOM_RECORD_AMOUNT_LIMIT
    if offset > 0  then
        local command_curtail_data_by_amount = string.format(
            command_curtail_data_by_amount, uid, cid_cond_str, offset)
        mysql_obj:query(command_curtail_data_by_amount)
    end

    local current_time = skynet_time()
    local time_limit = shake_dice_conf.ROOM_RECORD_TIME_LIMIT
    local command_curtail_data_by_time = string.format(command_curtail_data_by_time, current_time, time_limit)
    mysql_obj:query(command_curtail_data_by_time)
end

function root:fetch_user_room_records(uid, offset_id, amount, cid)
    local tmp_command_fetch_user_room_records = [[
        SELECT
            `id`, `uid`, `rid`, `content`, `room_number`, `expend_room_card`,
            `room_close_time`, `game_type`, `round_limit`, `user_limit`, `game_mode`,
            `bet_slot_limit`, `carry_score`, `bet_tao_switch`, `big_game_mode`, `cid`
        FROM
            `user_room_records`
        WHERE
            `uid`=%d %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]
    local cid_cond_str = ""
    if cid then
        cid_cond_str = " and `cid`=" .. cid
    end
    local command_fetch_user_room_records = nil
    if offset_id <= 0 then
        command_fetch_user_room_records = string.format(
            tmp_command_fetch_user_room_records,
            uid, "" .. cid_cond_str, amount
        )
    else
        command_fetch_user_room_records = string.format(
            tmp_command_fetch_user_room_records,
            uid, "and id<" .. offset_id .. cid_cond_str, amount
        )
    end
    local res = mysql_obj:query(command_fetch_user_room_records)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        local content = cjson_decode(tmp.content)
        local room_create_info = {
            room_number = tmp.room_number,
            expend_room_card = tmp.expend_room_card,
            room_close_time = tmp.room_close_time,
            game_type = tmp.game_type,
            round_limit = tmp.round_limit,
            user_limit = tmp.user_limit,
            game_mode = tmp.game_mode,
            bet_slot_limit = tmp.bet_slot_limit,
            carry_score = tmp.carry_score,
            bet_tao_switch = tmp.bet_tao_switch,
            big_game_mode = tmp.big_game_mode,
            cid = tmp.cid,
            rid = tmp.rid
        }
        content.id = tmp.id
        content.room_create_info = room_create_info
        table.insert(results_list, content)
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:insert_room_records(param)
    local command_insert_room_records = [[
        INSERT INTO `room_records`(
            `rid`, `room_number`, `owner_uid`, `consumer_uid`, `expend_room_card`,
            `expend`, `status`, `round_limit`, `user_limit`, `bet_slot_limit`,
            `carry_score`, `game_type`, `game_mode`, `big_game_mode`, `cid`,
            `create_date`, `finish_date`
        ) VALUES(
            %d, '%s', %d, %d, %d,
            %d, %d, %d, %d, %d,
            %d, %d, %d, %d, %d,
            '%s', '%s'
        )
    ]]
    local command_insert_room_records = string.format(command_insert_room_records,
        param.rid, param.room_number, param.owner_uid, param.consumer_uid, param.expend_room_card,
        param.expend, param.status, param.round_limit, param.user_limit, param.bet_slot_limit,
        param.carry_score, param.game_type, param.game_mode, param.big_game_mode, param.cid,
        param.create_date, param.finish_date
    )
    mysql_obj:query(command_insert_room_records)
end

function root:update_room_record(rid, expend, status, finish_date)
    local command_update_room_record = [[
        UPDATE
            `room_records`
        SET
            `expend`=%d,
            `status`=%d,
            `finish_date`='%s'
        WHERE
            `rid`=%d
        LIMIT 1;
    ]]
    local command_update_room_record = string.format(
        command_update_room_record, expend, status, finish_date, rid
    )
    mysql_obj:query(command_update_room_record)
end

function root:fetch_system_setting_content_by_type(tmp_type)
    local command_fetch_system_setting_content_by_type = [[
        SELECT
            `content`
        FROM
            `system_settings`
        WHERE
            `type`=%d
        LIMIT 1;
    ]]
    local command_fetch_system_setting_content_by_type = string.format(
        command_fetch_system_setting_content_by_type, tmp_type
    )
    local res = mysql_obj:query(command_fetch_system_setting_content_by_type)
    local content = nil
    while next(res) do
        local tmp = table.remove(res)
        content = tmp.content
    end
    if not content then
        return false
    end
    return true, content
end

function root:insert_transfer_account_records(source_uid, source_room_card, target_uid, target_room_card, transfer_time, amount)
    local command_insert_transfer_account_records = [[
        INSERT INTO `transfer_account_records`(
            `source_uid`, `source_room_card`, `target_uid`, `target_room_card`, `transfer_time`, `amount`
        ) VALUES(
            %d, %d, %d, %d, %d, %d
        );
    ]]
    local command_insert_transfer_account_records = string.format(
        command_insert_transfer_account_records,
        source_uid, source_room_card, target_uid, target_room_card, transfer_time, amount
    )
    mysql_obj:query(command_insert_transfer_account_records)
end

function root:fetch_transfer_account_records(uid, offset_id, amount)
    local tmp_command_fetch_transfer_account_records = [[
        SELECT
            `id`, `target_uid`, `transfer_time`, `amount`
        FROM
            `transfer_account_records`
        WHERE
            `source_uid`=%d %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]

    local command_fetch_transfer_account_records = nil
    if offset_id <= 0 then
        command_fetch_transfer_account_records = string.format(
            tmp_command_fetch_transfer_account_records,
            uid, "", amount
        )
    else
        command_fetch_transfer_account_records = string.format(
            tmp_command_fetch_transfer_account_records,
            uid, "and id<" .. offset_id, amount
        )
    end
    
    local res = mysql_obj:query(command_fetch_transfer_account_records)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id,
            target_uid = tmp.target_uid,
            transfer_time = tmp.transfer_time,
            amount = tmp.amount
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:fetch_game_operations_status()
    local command_fetch_operations_status = [[
        SELECT
            *
        FROM
            game_operations_status
        LIMIT 1;
    ]]
    local res = mysql_obj:query(command_fetch_operations_status)
    local status = common_conf.GAME_OPERATIONS_STATUS_STOP
    while next(res) do
        local tmp = table.remove(res)
        status = tmp.status
    end
    return status
end

function root:update_game_operations_status(status)
    local command_update_operations_status = [[
        UPDATE
            game_operations_status
        SET
            status=%d;
    ]]
    local command_update_operations_status = string.format(
        command_update_operations_status,
        status
    )
    mysql_obj:query(command_update_operations_status)
end

function root:insert_club_chip_increase_records(cid, source_uid, target_uid, increase_time, amount)
    local command_insert_club_chip_increase_records = [[
        INSERT INTO `club_chip_increase_records`(
            `cid`, `source_uid`, `target_uid`, `increase_time`, `amount`
        ) VALUES(
            %d, %d, %d, %d, %d
        );
    ]]
    local command_insert_club_chip_increase_records = string.format(
        command_insert_club_chip_increase_records,
        cid, source_uid, target_uid, increase_time, amount
    )
    mysql_obj:query(command_insert_club_chip_increase_records)
end

function root:fetch_club_chip_increase_records_normal(cid, uid, offset_id, amount)
    local tmp_command_fetch_club_chip_increase_records = [[
        SELECT
            `id`, `cid`, `source_uid`, `target_uid`, `increase_time`, `amount`
        FROM
            `club_chip_increase_records`
        WHERE
            `cid`=%d and `target_uid`=%d %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]
    local command_fetch_game_user_nick_name_avatar = [[
        SELECT
            `nick_name`,
            `avatar`
        FROM
            `game_users`
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_fetch_club_chip_increase_records = nil
    if offset_id <= 0 then
        command_fetch_club_chip_increase_records = string.format(
            tmp_command_fetch_club_chip_increase_records,
            cid, uid, "", amount
        )
    else
        command_fetch_club_chip_increase_records = string.format(
            tmp_command_fetch_club_chip_increase_records,
            cid, uid, "and id<" .. offset_id, amount
        )
    end
    local res = mysql_obj:query(command_fetch_club_chip_increase_records)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        local target_uid = tmp.target_uid
        local command_fetch_game_user_nick_name_avatar = string.format(
            command_fetch_game_user_nick_name_avatar,
            target_uid
        )
        local tmp_res = mysql_obj:query(command_fetch_game_user_nick_name_avatar)
        local target_nick_name = ""
        local target_avatar = ""
        while next(tmp_res) do
            local tmp_tmp = table.remove(tmp_res)
            target_nick_name = tmp_tmp.nick_name
            target_avatar = tmp_tmp.avatar
        end
        table.insert(results_list, {
            id = tmp.id,
            source_uid = tmp.source_uid,
            target_uid = target_uid,
            target_nick_name = target_nick_name,
            target_avatar = target_avatar,
            increase_time = tmp.increase_time,
            amount = tmp.amount
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:fetch_club_chip_increase_records_manager(cid, offset_id, amount)
    local tmp_command_fetch_club_chip_increase_records = [[
        SELECT
            `id`, `cid`, `source_uid`, `target_uid`, `increase_time`, `amount`
        FROM
            `club_chip_increase_records`
        WHERE
            `cid`=%d %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]
    local command_fetch_game_user_nick_name_avatar = [[
        SELECT
            `nick_name`,
            `avatar`
        FROM
            `game_users`
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_fetch_club_chip_increase_records = nil
    if offset_id <= 0 then
        command_fetch_club_chip_increase_records = string.format(
            tmp_command_fetch_club_chip_increase_records,
            cid, "", amount
        )
    else
        command_fetch_club_chip_increase_records = string.format(
            tmp_command_fetch_club_chip_increase_records,
            cid, "and id<" .. offset_id, amount
        )
    end
    local res = mysql_obj:query(command_fetch_club_chip_increase_records)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        local target_uid = tmp.target_uid
        local command_fetch_game_user_nick_name_avatar = string.format(
            command_fetch_game_user_nick_name_avatar,
            target_uid
        )
        local tmp_res = mysql_obj:query(command_fetch_game_user_nick_name_avatar)
        local target_nick_name = ""
        local target_avatar = ""
        while next(tmp_res) do
            local tmp_tmp = table.remove(tmp_res)
            target_nick_name = tmp_tmp.nick_name
            target_avatar = tmp_tmp.avatar
        end
        table.insert(results_list, {
            id = tmp.id,
            source_uid = tmp.source_uid,
            target_uid = target_uid,
            target_nick_name = target_nick_name,
            target_avatar = target_avatar,
            increase_time = tmp.increase_time,
            amount = tmp.amount
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:delete_club_chip_increase_records(cid)
    local command_delete_club_chip_increase_records = [[
        DELETE FROM
            `club_chip_increase_records`
        WHERE
            `cid`=%d;
    ]]
    local command_delete_club_chip_increase_records = string.format(command_delete_club_chip_increase_records, cid)
    mysql_obj:query(command_delete_club_chip_increase_records)
end

function root:insert_payment_records(uid, type, price, buy, state, mode, order_number, discount)
    local command_insert_payment_records = [[
        INSERT INTO `payment_records`(
            `uid`, `type`, `price`, `buy`, `state`,
            `mode`, `time`, `order_number`, `discount`
        ) VALUES(
            %d, %d, %d, %d, %d,
            %d, unix_timestamp(now()), '%s', %d
        );
    ]]
    local command_insert_payment_records = string.format(
        command_insert_payment_records,
        uid, type, price, buy, state,
        mode, order_number, discount
    )
    mysql_obj:query(command_insert_payment_records)
end

function root:update_payment_record_state(state, order_number)
    local command_update_payment_record_state = [[
        UPDATE
            `payment_records`
        SET
            `state`=%d
        WHERE
            `order_number`='%s'
        LIMIT 1;
    ]]
    local command_update_payment_record_state = string.format(
        command_update_payment_record_state,
        state, order_number
    )
    mysql_obj:query(command_update_payment_record_state)
end

function root:is_exist_payment_record_by_ordernumber(order_number)
    local command_is_exist_payment_record_by_ordernumber = [[
        SELECT IFNULL( (SELECT 'Y' FROM `payment_records` WHERE `order_number`='%s' LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_payment_record_by_ordernumber = string.format(command_is_exist_payment_record_by_ordernumber, order_number)
    local res = mysql_obj:query(command_is_exist_payment_record_by_ordernumber)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_payment_record_succeed_by_ordernumber(order_number, state)
    local command_is_exist_payment_record_succeed_by_ordernumber = [[
        SELECT IFNULL( (SELECT 'Y' FROM `payment_records` WHERE `order_number`='%s' and `state`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_payment_record_succeed_by_ordernumber = string.format(
        command_is_exist_payment_record_succeed_by_ordernumber, order_number, state)
    local res = mysql_obj:query(command_is_exist_payment_record_succeed_by_ordernumber)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:is_exist_invite_code_by_uid(uid)
    local command_is_exist_invite_code_by_uid = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `invite_codes` WHERE `uid`=%d LIMIT 1), 'N' ) is_exist;
    ]]
    local command_is_exist_invite_code_by_uid = string.format(
        command_is_exist_invite_code_by_uid, uid)
    local res = mysql_obj:query(command_is_exist_invite_code_by_uid)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:insert_invite_code_for_agent(
    uid, role,
    next_agent_recharge_discount,
    next_agent_recharge_current_agent_rebate,
    next_agent_bound_invite_code_gift_amount,
    next_agent_bound_invite_code_gift_type)
    local command_insert_invite_code_for_agent = [[
        INSERT INTO `invite_codes`(
            `uid`, `role`,
            `next_agent_recharge_discount`,
            `next_agent_recharge_current_agent_rebate`,
            `next_agent_bound_invite_code_gift_amount`,
            `next_agent_bound_invite_code_gift_type`,
            `remark`
        ) VALUES(
            %d, %d, %d, %d, %d, %d, '%s'
        );
    ]]
    local command_insert_invite_code_for_agent = string.format(
        command_insert_invite_code_for_agent,
        uid, role,
        next_agent_recharge_discount,
        next_agent_recharge_current_agent_rebate,
        next_agent_bound_invite_code_gift_amount,
        next_agent_bound_invite_code_gift_type,
        common_conf.INVITE_CODE_AGENT_REMARK
    )
    mysql_obj:query(command_insert_invite_code_for_agent)
end

function root:is_exist_invite_code_by_invite_code(invite_code)
    local command_is_exist_invite_code_by_invite_code = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `invite_codes` WHERE `id` = %d LIMIT 1 ), 'N' ) is_exist;
    ]]
    local command_is_exist_invite_code_by_invite_code = string.format(
        command_is_exist_invite_code_by_invite_code, invite_code)
    local res = mysql_obj:query(command_is_exist_invite_code_by_invite_code)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:fetch_invite_code_by_id(id)
    local command_fetch_invite_code = [[
        SELECT
            `id`, `uid`, `role`,
            `partner_recharge_discount`, `super_agent_recharge_discount`,
            `normal_agent_recharge_partner_rebate`, `super_agent_recharge_partner_rebate`,
            `super_agent_bound_invite_code_gift_amount`, `super_agent_bound_invite_code_gift_type`,
            `next_agent_recharge_discount`, `next_agent_recharge_current_agent_rebate`,
            `next_agent_bound_invite_code_gift_amount`, `next_agent_bound_invite_code_gift_type`,
            `remark`
        FROM
            `invite_codes`
        WHERE
            `id`=%d
        LIMIT 1;
    ]]
    local command_fetch_invite_code = string.format(command_fetch_invite_code, id)
    local res = mysql_obj:query(command_fetch_invite_code)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.id = tmp.id
        results.uid = tmp.uid
        results.role = tmp.role
        results.partner_recharge_discount = tmp.partner_recharge_discount
        results.super_agent_recharge_discount = tmp.super_agent_recharge_discount
        results.normal_agent_recharge_partner_rebate = tmp.normal_agent_recharge_partner_rebate
        results.super_agent_recharge_partner_rebate = tmp.super_agent_recharge_partner_rebate
        results.super_agent_bound_invite_code_gift_amount = tmp.super_agent_bound_invite_code_gift_amount
        results.super_agent_bound_invite_code_gift_type = tmp.super_agent_bound_invite_code_gift_type
        results.next_agent_recharge_discount = tmp.next_agent_recharge_discount
        results.next_agent_recharge_current_agent_rebate = tmp.next_agent_recharge_current_agent_rebate
        results.next_agent_bound_invite_code_gift_amount = tmp.next_agent_bound_invite_code_gift_amount
        results.next_agent_bound_invite_code_gift_type = tmp.next_agent_bound_invite_code_gift_type
        results.remark = tmp.remark
    end
    return results
end

function root:fetch_invite_code_by_uid(uid)
    local command_fetch_invite_code = [[
        SELECT
            `id`, `uid`, `role`,
            `partner_recharge_discount`, `super_agent_recharge_discount`,
            `normal_agent_recharge_partner_rebate`, `super_agent_recharge_partner_rebate`,
            `super_agent_bound_invite_code_gift_amount`, `super_agent_bound_invite_code_gift_type`,
            `next_agent_recharge_discount`, `next_agent_recharge_current_agent_rebate`,
            `next_agent_bound_invite_code_gift_amount`, `next_agent_bound_invite_code_gift_type`,
            `remark`
        FROM
            `invite_codes`
        WHERE
            `uid`=%d
        LIMIT 1;
    ]]
    local command_fetch_invite_code = string.format(command_fetch_invite_code, uid)
    local res = mysql_obj:query(command_fetch_invite_code)
    local results = {}
    while next(res) do
        local tmp = table.remove(res)
        results.id = tmp.id
        results.uid = tmp.uid
        results.role = tmp.role
        results.partner_recharge_discount = tmp.partner_recharge_discount
        results.super_agent_recharge_discount = tmp.super_agent_recharge_discount
        results.normal_agent_recharge_partner_rebate = tmp.normal_agent_recharge_partner_rebate
        results.super_agent_recharge_partner_rebate = tmp.super_agent_recharge_partner_rebate
        results.super_agent_bound_invite_code_gift_amount = tmp.super_agent_bound_invite_code_gift_amount
        results.super_agent_bound_invite_code_gift_type = tmp.super_agent_bound_invite_code_gift_type
        results.next_agent_recharge_discount = tmp.next_agent_recharge_discount
        results.next_agent_recharge_current_agent_rebate = tmp.next_agent_recharge_current_agent_rebate
        results.next_agent_bound_invite_code_gift_amount = tmp.next_agent_bound_invite_code_gift_amount
        results.next_agent_bound_invite_code_gift_type = tmp.next_agent_bound_invite_code_gift_type
        results.remark = tmp.remark
    end
    return results
end

function root:insert_brokerage_records(uid, consumer_uid, cost, brokerage, time)
    local command_insert_brokerage_records = [[
        INSERT INTO `brokerage_records`(
            `uid`, `consumer_uid`, `cost`, `brokerage`, `time`
        ) VALUES(
            %d, %d, %d, %d, %d
        );
    ]]
    local command_insert_brokerage_records = string.format(
        command_insert_brokerage_records,
        uid, consumer_uid, cost, brokerage, time
    )
    mysql_obj:query(command_insert_brokerage_records)
end

function root:insert_single_chats(source_uid, target_uid, type, content, time, remind)
    local command_insert_single_chats = [[
        INSERT INTO `single_chats`(
            `source_uid`, `target_uid`, `type`, `content`, `time`,
            `remind`, `unread`
        ) VALUES(
            %d, %d, %d, '%s', %d, %d, %d
        );
    ]]
    local command_insert_single_chats = string.format(
        command_insert_single_chats,
        source_uid, target_uid, type, content, time,
        remind, common_conf.CHAT_UNREAD
    )
    mysql_obj:query(command_insert_single_chats)
end

function root:fetch_single_chats(source_uid, target_uid, offset_id, amount)
    local tmp_command_fetch_single_chats = [[
        SELECT
            `id`, `source_uid`, `target_uid`, `type`, `content`,
            `time`
        FROM
            `single_chats`
        WHERE
            (
                (`source_uid`=%d and `target_uid`=%d) or
                (`source_uid`=%d and `target_uid`=%d)
            ) %s
        ORDER BY
            `id`
        DESC LIMIT 0, %d;
    ]]
    local command_fetch_single_chats = nil
    if offset_id <= 0 then
        command_fetch_single_chats = string.format(
            tmp_command_fetch_single_chats,
            source_uid, target_uid, target_uid, source_uid, "", amount
        )
    else
        command_fetch_single_chats = string.format(
            tmp_command_fetch_single_chats,
            source_uid, target_uid, target_uid, source_uid, "and id<" .. offset_id, amount
        )
    end
    local res = mysql_obj:query(command_fetch_single_chats)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id, source_uid = tmp.source_uid, target_uid = tmp.target_uid, type = tmp.type, content = tmp.content,
            time = tmp.time
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.id > v2.id
    end)
    return results_list
end

function root:fetch_single_chats_only(source_uid, target_uid)
    local command_fetch_single_chats_only = [[
        SELECT
            MAX(`id`) as `id`, `source_uid`, `target_uid`, MAX(`remind`) as `remind`, MAX(`time`) as `time`,
            SUM(`unread`) unread_amount
        FROM
            `single_chats`
        WHERE
            `source_uid`=%d or `target_uid`=%d
        GROUP BY
            `source_uid`, `target_uid`;
    ]]
    local command_fetch_single_chats_only = string.format(
        command_fetch_single_chats_only,
        source_uid, target_uid
    )
    local res = mysql_obj:query(command_fetch_single_chats_only)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id,
            source_uid = tmp.source_uid,
            target_uid = tmp.target_uid,
            remind = tmp.remind,
            time = tmp.time,
            unread_amount = tmp.unread_amount
        })
    end
    return results_list
end

function root:fetch_single_chats_only_special(source_uid, target_uid)
    local command_fetch_single_chats_only_special = [[
        SELECT
            MAX(`id`) as `id`, `source_uid`, `target_uid`, `type`, `content`,
            `remind`, `time`, SUM(`unread`) unread_amount
        FROM
            `single_chats`
        WHERE
            `source_uid`=%d and `target_uid`=%d
        GROUP BY
            `source_uid`, `target_uid`;
    ]]
    local command_fetch_single_chats_only_special = string.format(
        command_fetch_single_chats_only_special,
        source_uid, target_uid
    )
    local res = mysql_obj:query(command_fetch_single_chats_only_special)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id, source_uid = tmp.source_uid, target_uid = tmp.target_uid, type = tmp.type, content = tmp.content,
            remind = tmp.remind, time = tmp.time, unread_amount = tmp.unread_amount
        })
    end
    return results_list
end

function root:fetch_single_chats_newest(source_uid, target_uid)
    local command_fetch_single_chats_newest = [[
        SELECT
            `id`, `source_uid`, `target_uid`, `type`, `content`,
            `time`
        FROM
            `single_chats`
        WHERE
            (`source_uid`=%d and `target_uid`=%d) or (`source_uid`=%d and `target_uid`=%d)
        ORDER BY
            `id`
        DESC LIMIT 1;
    ]]
    local command_fetch_single_chats_newest = string.format(
        command_fetch_single_chats_newest,
        source_uid, target_uid, target_uid, source_uid
    )
    local res = mysql_obj:query(command_fetch_single_chats_newest)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        table.insert(results_list, {
            id = tmp.id, source_uid = tmp.source_uid, target_uid = tmp.target_uid, type = tmp.type, content = tmp.content,
            time = tmp.time
        })
    end
    return results_list
end

function root:curtail_single_chats(source_uid, target_uid)
    local command_fetch_amount = [[
        SELECT
            COUNT(1) `amount`
        FROM
            `single_chats`
        WHERE
            (`source_uid`=%d and `target_uid`=%d) or (`source_uid`=%d and `target_uid`=%d);
    ]]
    local command_curtail_data_by_amount = [[
        DELETE FROM
            `single_chats`
        WHERE
            (`source_uid`=%d and `target_uid`=%d) or (`source_uid`=%d and `target_uid`=%d)
        ORDER BY `id` ASC limit %d;
    ]]
    local command_curtail_data_by_time = [[
        DELETE FROM
            `single_chats`
        WHERE
            `time`<%d;
    ]]

    local current_time = skynet_time()
    local offset = current_time - common_conf.CHAT_LIST_LIFE_CYCLE_TIME
    local command_curtail_data_by_time = string.format(command_curtail_data_by_time, offset)
    mysql_obj:query(command_curtail_data_by_time)

    local command_fetch_amount = string.format(
        command_fetch_amount,
        source_uid, target_uid, target_uid, source_uid
    )
    local res = mysql_obj:query(command_fetch_amount)
    local amount = 0
    while next(res) do
        local tmp = table.remove(res)
        amount = tmp.amount
    end
    local offset = amount - common_conf.CLUB_CHAT_AMOUNT_LIMIT
    if offset > 0 then
        local command_curtail_data_by_amount = string.format(
            command_curtail_data_by_amount, 
            source_uid, target_uid, target_uid, source_uid, offset
        )
        mysql_obj:query(command_curtail_data_by_amount)
    end
end

function root:reset_single_chats_unread_amount(source_uid, target_uid)
    local command_reset_single_chats_unread_amount = [[
        UPDATE
            `single_chats`
        SET
            `unread`=0
        WHERE
            `source_uid`=%d and `target_uid`=%d;
    ]]
    local command_reset_single_chats_unread_amount = string.format(
        command_reset_single_chats_unread_amount,
        source_uid, target_uid
    )
    mysql_obj:query(command_reset_single_chats_unread_amount)
end

function root:update_single_chats_remind(source_uid, target_uid, remind)
    local command_update_single_chats_remind = [[
        UPDATE
            `single_chats`
        SET
            `remind`=%d
        WHERE
            `source_uid`=%d and `target_uid`=%d;
    ]]
    local command_update_single_chats_remind = string.format(
        command_update_single_chats_remind,
        remind, source_uid, target_uid
    )
    mysql_obj:query(command_update_single_chats_remind)
end

function root:fetch_game_notices()
    local command_fetch_game_notices = [[
        SELECT
            `title`, `popup`, `sort`, `type`, `content`
        FROM
            `game_notices`
        WHERE
            `status`=%d
        ORDER BY
            `sort`
        DESC;
    ]]
    local command_fetch_game_notices = string.format(
        command_fetch_game_notices, common_conf.NOTICE_STATUS_ON
    )
    local res = mysql_obj:query(command_fetch_game_notices)
    local results_list = {}
    while next(res) do
        local tmp = table.remove(res)
        local content_type = tmp.type
        local content = tmp.content
        if content_type == common_conf.NOTICE_TYPE_IMAGE then
            content = common_conf.NOTICE_IMAGE_ADDRESS .. content
        end
        table.insert(results_list, {
            title = tmp.title,
            popup = tmp.popup,
            sort = tmp.sort,
            type = content_type,
            content = content
        })
    end
    table.sort(results_list, function(v1, v2)
        return v1.sort < v2.sort
    end)
    return results_list
end

return root
