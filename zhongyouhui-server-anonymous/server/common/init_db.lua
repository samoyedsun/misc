local rpc_mysql = require "rpc_mysql"
local mysql_obj = rpc_mysql.get_mysql("zhongyouhui")
local common_db = require "server.common.common_db"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_common_init_db")

local function init_room_number()
    local room_num_list = {}
    for num = common_conf.ROOM_NUM_MIN, common_conf.ROOM_NUM_MAX do
        table.insert(room_num_list, num)
    end

    local command_lock_room_numbers = "LOCK TABLES room_numbers WRITE;"
    local command_unlock_room_numbers = "UNLOCK TABLES;"
    local command_exists_table = [[
        SELECT
            table_name
        FROM
            information_schema.TABLES
        WHERE
            table_name='room_numbers'
        LIMIT 1;
    ]]
    local command_create_table = [[
        CREATE TABLE IF NOT EXISTS `room_numbers`(
            id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            room_number varchar(6) NOT NULL,
            in_use tinyint(1) NOT NULL,
            rid int(10) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    local command_insert_number = [[
        INSERT INTO room_numbers(
            room_number,
            in_use,
            rid
        ) VALUES(
            '%s',
            %d,
            %d
        )
    ]]

    local db = common_db:create_mysql_connect()
    common_db:query_by_mysql_connect(db, command_lock_room_numbers)
    local res = common_db:query_by_mysql_connect(db, command_exists_table)
    if #res > 0 then
        logger.debug("room num already initialization!")
        common_db:query_by_mysql_connect(db, command_unlock_room_numbers)
        common_db:close_mysql_connect(db)
        return nil
    end
    local res = common_db:query_by_mysql_connect(db, command_create_table)
    local in_use = 0
    local rid = 0
    for idx = common_conf.ROOM_NUM_MIN, common_conf.ROOM_NUM_MAX do
        local pos = math.random(1, #room_num_list)
        local number = table.remove(room_num_list, pos)
        local number = string.format("%06d", number)
        local command_insert_number = string.format(command_insert_number, number, in_use, rid)

        local res = common_db:query_by_mysql_connect(db, command_insert_number)
    end
    common_db:query_by_mysql_connect(db, command_unlock_room_numbers)
    common_db:close_mysql_connect(db)
end


local function init_rid_seed()
    local command_create_rid_seed = [[
        CREATE TABLE IF NOT EXISTS `rid_seed` (
            `rid` int(10) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_create_rid_seed)
end

local function init_uid_seed()
    local command_create_uid_seed = [[
        CREATE TABLE IF NOT EXISTS `uid_seed` (
            `uid` int(10) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_create_uid_seed)
end

local function init_cid_seed()
    local command_create_cid_seed = [[
        CREATE TABLE IF NOT EXISTS `cid_seed` (
            `cid` int(10) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_create_cid_seed)
end

local function init_game_users()
    local command_create_game_users = [[
        CREATE TABLE IF NOT EXISTS `game_users` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `avatar` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `nick_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `gold_coin` bigint(20) NOT NULL,
            `diamond` bigint(20) NOT NULL,
            `room_card` bigint(20) NOT NULL,
            `gender` tinyint(4) NOT NULL,
            `sound` tinyint(4) NOT NULL,
            `music` tinyint(4) NOT NULL,
            `rid` int(10) NOT NULL DEFAULT 0,
            `online` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `agency` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `discount` tinyint(4) unsigned NOT NULL DEFAULT 60,
            `invite_code` bigint(20) unsigned NOT NULL DEFAULT 0,
            `invite_code_time` bigint(20) unsigned NOT NULL DEFAULT 0,
            `phone_number` varchar(255) default "",
            `language` varchar(255) default "",
            `city` varchar(255) default "",
            `province` varchar(255) default "",
            `country` varchar(255) default "",
            `privilege` varchar(255) default "",
            `unionid` varchar(255) default "",
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_create_game_users)
end

local function init_wechat_tokens()
    local command_create_wechat_tokens = [[
        CREATE TABLE IF NOT EXISTS `wechat_tokens` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `expires_in` bigint(20) unsigned NOT NULL,
            `refresh_time` bigint(20) unsigned NOT NULL,
            `platform` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `openid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `access_token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `refresh_token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `unionid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_create_wechat_tokens)
end

local function init_game_rooms()
    local command_create_game_rooms = [[
        CREATE TABLE IF NOT EXISTS `game_rooms`(
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `owner_uid` int(10) NOT NULL,
            `round_limit` int(10) NOT NULL,
            `user_limit` int(10) NOT NULL,
            `game_mode` int(10) NOT NULL,
            `bet_slot_limit` int(10) NOT NULL,
            `carry_score` int(10) NOT NULL,
            `banker_uid` int(10) NOT NULL,
            `game_type` int(10) NOT NULL,
            `big_game_mode` int(10) NOT NULL,
            `cid` int(10) NOT NULL,
            `room_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `rid` int(10) NOT NULL,
            `skynet_service_id` int(10) NOT NULL,
            `status` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_create_game_rooms) 
end

local function init_recharge_settings()
    local command_recharge_settings = [[
        CREATE TABLE IF NOT EXISTS `recharge_settings` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `type` tinyint(3) unsigned NOT NULL,
            `price` int(10) unsigned NOT NULL,
            `buy` int(10) unsigned NOT NULL,
            `show` tinyint(3) unsigned NOT NULL,
            `show_type` tinyint(3) unsigned NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_recharge_settings)
end

local function init_user_room_records()
    local command_user_room_records = [[
        CREATE TABLE IF NOT EXISTS `user_room_records`(
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `rid` int(10) NOT NULL,
            `content` longtext NOT NULL,
            `room_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `expend_room_card` int(10) NOT NULL,
            `room_close_time` bigint(20) unsigned NOT NULL,
            `game_type` int(10) NOT NULL,
            `round_limit` int(10) NOT NULL,
            `user_limit` int(10) NOT NULL,
            `game_mode` int(10) NOT NULL,
            `bet_slot_limit` int(10) NOT NULL,
            `carry_score` int(10) NOT NULL,
            `bet_tao_switch` int(10) NOT NULL,
            `big_game_mode` int(10) NOT NULL,
            `cid` int(10) NOT NULL,
            `total_score` int(10) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_user_room_records)
end

local function init_system_settings()
    local command_system_settings = [[
        CREATE TABLE IF NOT EXISTS `system_settings` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `type` tinyint(4) unsigned NOT NULL,
            `content` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_system_settings)
end



local function init_transfer_account_records()
    local command_transfer_account_records = [[
        CREATE TABLE IF NOT EXISTS `transfer_account_records` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `source_uid` int(10) NOT NULL,
            `source_room_card` int(10) NOT NULL DEFAULT 0,
            `target_uid` int(10) NOT NULL,
            `target_room_card` int(10) NOT NULL DEFAULT 0,
            `transfer_time` bigint(20) unsigned NOT NULL,
            `amount` bigint(20) NOT NULL,
            `type` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `status` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_transfer_account_records)
end

local function init_game_operations_status()
    local command_exists_table = [[
        SELECT
            table_name
        FROM
            information_schema.TABLES
        WHERE
            table_name='game_operations_status'
        LIMIT 1;
    ]]
    local command_game_operations_status = [[
        CREATE TABLE IF NOT EXISTS `game_operations_status` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `status` tinyint(4) unsigned NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    local command_insert_operations_status = [[
        INSERT INTO game_operations_status(
            status
        ) VALUES(
            %d
        )
    ]]
    local command_update_operations_status = [[
        UPDATE
            game_operations_status
        SET
            status=%d;
    ]]
    local res = mysql_obj:query(command_exists_table)
    if #res > 0 then
        local command_update_operations_status = string.format(
            command_update_operations_status,
            common_conf.GAME_OPERATIONS_STATUS_RUNNING
        )
        mysql_obj:query(command_update_operations_status)
    else
        mysql_obj:query(command_game_operations_status)

        local command_insert_operations_status = string.format(
            command_insert_operations_status,
            common_conf.GAME_OPERATIONS_STATUS_RUNNING
        )
        mysql_obj:query(command_insert_operations_status)
    end
end

local function init_game_clubs()
    local command_game_clubs = [[
        CREATE TABLE IF NOT EXISTS `game_clubs` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `cid` int(10) NOT NULL,
            `club_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `announcement` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `total_club_chip` bigint(20) NOT NULL,
            `join_rank` tinyint(4) unsigned NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_game_clubs)
end

local function init_club_members()
    local command_club_members = [[
        CREATE TABLE IF NOT EXISTS `club_members` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `cid` int(10) NOT NULL,
            `uid` int(10) NOT NULL,
            `club_chip` bigint(20) NOT NULL,
            `status` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `unread_amount` int(10) unsigned NOT NULL DEFAULT 0,
            `remind` tinyint(4) unsigned NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_club_members)
end

local function init_club_applys()
    local command_club_applys = [[
        CREATE TABLE IF NOT EXISTS `club_applys` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `cid` int(10) NOT NULL,
            `status` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_club_applys)
end

local function init_club_chip_increase_records()
    local command_club_chip_increase_records = [[
        CREATE TABLE IF NOT EXISTS `club_chip_increase_records` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `cid` int(10) NOT NULL,
            `source_uid` int(10) NOT NULL,
            `target_uid` int(10) NOT NULL,
            `increase_time` bigint(20) unsigned NOT NULL,
            `amount` bigint(20) NOT NULL,
            `type` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `status` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_club_chip_increase_records)
end

local function init_payment_records()
    local command_payment_records = [[
        CREATE TABLE IF NOT EXISTS `payment_records` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `type` tinyint(3) unsigned NOT NULL,
            `price` int(10) unsigned NOT NULL,
            `buy` int(10) unsigned NOT NULL,
            `state` tinyint(3) unsigned NOT NULL,
            `mode` tinyint(3) unsigned NOT NULL,
            `time` bigint(20) unsigned NOT NULL,
            `order_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `discount` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_payment_records)
end

local function init_invite_codes()
    local command_invite_codes = [[
        CREATE TABLE IF NOT EXISTS `invite_codes` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `role` tinyint(4) unsigned NOT NULL,
            `partner_recharge_discount` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `super_agent_recharge_discount` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `normal_agent_recharge_partner_rebate` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `super_agent_recharge_partner_rebate` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `super_agent_bound_invite_code_gift_amount` int(10) NOT NULL DEFAULT 0,
            `super_agent_bound_invite_code_gift_type` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `next_agent_recharge_discount` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `next_agent_recharge_current_agent_rebate` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `next_agent_bound_invite_code_gift_amount` int(10) NOT NULL DEFAULT 0,
            `next_agent_bound_invite_code_gift_type` tinyint(4) unsigned NOT NULL DEFAULT 0,
            `remark` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`),
            UNIQUE KEY (`uid`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1216 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_invite_codes)
end

local function init_room_records()
    local command_room_records = [[
        CREATE TABLE IF NOT EXISTS `room_records`(
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `rid` int(10) NOT NULL,
            `room_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `owner_uid` int(10) NOT NULL,
            `consumer_uid` int(10) NOT NULL,
            `expend_room_card`int(10) NOT NULL,
            `expend` tinyint(4) unsigned NOT NULL,
            `status` tinyint(4) unsigned NOT NULL,
            `round_limit` int(10) NOT NULL,
            `user_limit` int(10) NOT NULL,
            `bet_slot_limit` int(10) NOT NULL,
            `carry_score` int(10) NOT NULL,
            `game_type` int(10) NOT NULL,
            `game_mode` int(10) NOT NULL,
            `big_game_mode` int(10) NOT NULL,
            `cid` int(10) NOT NULL,
            `create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `finish_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '关闭时间',
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_room_records)
end

local function init_brokerage_records()
    local command_brokerage_records = [[
        CREATE TABLE IF NOT EXISTS `brokerage_records` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `consumer_uid` int(10) NOT NULL,
            `cost` bigint(20) unsigned NOT NULL,
            `brokerage` bigint(20) unsigned NOT NULL,
            `time` bigint(20) unsigned NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;        
    ]]
    mysql_obj:query(command_brokerage_records)
end

local function init_withdraw_records()
    local command_withdraw_records = [[
        CREATE TABLE IF NOT EXISTS `withdraw_records` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `money` bigint(20) unsigned NOT NULL,
            `account_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `status` tinyint(4) unsigned NOT NULL,
            `time` bigint(20) unsigned NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;   
    ]]
    mysql_obj:query(command_withdraw_records)
end

local function init_withdraw_channels()
    local command_withdraw_channels = [[
        CREATE TABLE IF NOT EXISTS `withdraw_channels` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `uid` int(10) NOT NULL,
            `type` tinyint(4) unsigned NOT NULL,
            `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `account_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_withdraw_channels)
end

local function init_club_chats()
    local command_club_chats = [[
        CREATE TABLE IF NOT EXISTS `club_chats` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `cid` int(10) NOT NULL,
            `uid` int(10) NOT NULL,
            `type` tinyint(4) unsigned NOT NULL,
            `content` longtext NOT NULL,
            `time` bigint(20) unsigned NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_club_chats)
end

local function init_single_chats()
    local command_single_chats = [[
        CREATE TABLE IF NOT EXISTS `single_chats` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `source_uid` int(10) NOT NULL,
            `target_uid` int(10) NOT NULL,
            `type` tinyint(4) unsigned NOT NULL,
            `content` longtext NOT NULL,
            `time` bigint(20) unsigned NOT NULL,
            `unread` tinyint(4) unsigned NOT NULL,
            `remind` tinyint(4) unsigned NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_single_chats)
end

local function init_game_notices()
    local command_game_notices = [[
        CREATE TABLE IF NOT EXISTS `game_notices` (
            `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
            `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
            `popup` tinyint(4) unsigned NOT NULL,
            `sort` tinyint(4) unsigned NOT NULL,
            `status` tinyint(4) unsigned NOT NULL,
            `type` tinyint(4) unsigned NOT NULL,
            `content` longtext NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    mysql_obj:query(command_game_notices)
end

return function()
    init_room_number()
    init_rid_seed()
    init_uid_seed()
    init_cid_seed()
    init_game_users()
    init_wechat_tokens()
    init_game_rooms()
    init_recharge_settings()
    init_user_room_records()
    init_system_settings()
    init_transfer_account_records()
    init_game_operations_status()
    init_game_clubs()
    init_club_members()
    init_club_applys()
    init_club_chip_increase_records()
    init_payment_records()
    init_invite_codes()
    init_room_records()
    init_brokerage_records()
    init_withdraw_records()
    init_withdraw_channels()
    init_club_chats()
    init_single_chats()
    init_game_notices()
    logger.debug("mysql init ok!")
end