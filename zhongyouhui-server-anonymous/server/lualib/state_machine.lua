local skynet = require "skynet"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_util = require "server.common.common_util"
local http_util = require "server.common.http_util"
local room = require "server.lualib.room"
local seat_mgr = require "server.lualib.seat_mgr"
local common_conf = require "server.config.common_conf"
local game_rooms_db = require "server.common.game_rooms_db"
local logger = log4.get_logger("server_lualib_state_machine")

local root = {}

function root:register_state_to_process()

    self.state_to_process[shake_dice_conf.GAME_STATE_WAIT_PLAY] = function()
        self.timer = create_timeout(shake_dice_conf.TIME_LIMIT_WAIT_PLAY * 100, function()
            room:close()
        end)
    end

    self.state_to_process[shake_dice_conf.GAME_STATE_GRAB_BANKER] = function()
        self.timer = create_timeout(shake_dice_conf.TIME_LIMIT_GRAB_BRANKER * 100, function()
            seat_mgr:random_select_banker()
            seat_mgr:broadcast("on_room_grab_banker", {
                seat_info_list = seat_mgr:seat_info_list()
            })
            local rid = room:get_rid()
            local banker_uid = seat_mgr:get_banker_uid()
            game_rooms_db:update_game_room_banker_uid_by_rid(rid, banker_uid)
            self:update(shake_dice_conf.GAME_STATE_SHAKE_DICE)
        end)
    end

    self.state_to_process[shake_dice_conf.GAME_STATE_SHAKE_DICE] = function()
        self.timer = create_timeout(shake_dice_conf.TIME_LIMIT_SHAKE_DICE * 100, function()
            room:mark_shake_dice_flag()

            seat_mgr:broadcast("on_room_shake_dice", {
            })
            self.timer = create_timeout(2 * 100, function() -- 预留摇骰子动画时间
                self:update(shake_dice_conf.GAME_STATE_BET)
            end)
        end)
    end

    self.state_to_process[shake_dice_conf.GAME_STATE_BET] = function()
        self.timer = create_timeout(shake_dice_conf.TIME_LIMIT_BET * 100, function()
            room:mark_open_dice_flag()

            room:set_real_open_dice_switch(true)
            room:set_open_dice_switch(true)
            while room:get_open_dice_switch() do
                skynet.sleep(10)
            end
            local blockchains_info = room:get_blockchains_info()
            seat_mgr:broadcast("on_room_open_dice", {
                blockchains_info = blockchains_info
            })
            self:update(shake_dice_conf.GAME_STATE_SETTLEMENT)
        end)

        -- 特殊处理，随时可能取消
        skynet.fork(function (game_state_bet_end_time)
            self.stop_loop_check_time_flag = true
            while self.stop_loop_check_time_flag do
                local real_start_time_offset = game_state_bet_end_time - skynet_time()
                if self.open_award_code_search_start_time_offset > 0 and
                    real_start_time_offset <= self.open_award_code_search_start_time_offset then
                    self.open_award_search_start_block_number = "mark"
                    self.stop_loop_check_time_flag = false
                end
                if self.open_award_code_search_start_time_offset > 0 then
                    logger.debug("实际编码:%d", self.open_award_code)
                    logger.debug("实际偏移值:%d", self.open_award_code_search_start_time_offset)
                end
                skynet.sleep(50)
            end
        end, skynet_time() + shake_dice_conf.TIME_LIMIT_BET)
    end

    self.state_to_process[shake_dice_conf.GAME_STATE_SETTLEMENT] = function()
        self.timer = create_timeout(shake_dice_conf.TIME_LIMIT_SETTLEMENT * 100, function()
            
            -- 特殊处理，随时可能取消
            local function sync_settlement_data_to_anonymous()
                local rid = room:get_rid()
                local anonymous_monitor_rid = skynet.call(".logon", "lua", "get_anonymous_monitor_rid")
                if anonymous_monitor_rid == rid then
                    local total_settlement_data = room:total_settlement()
                    local function get_total_score(uid)
                        for k, v in ipairs(total_settlement_data.total_settlement_info_list) do
                            if v.uid == uid then
                                return v.total_score
                            end
                        end
                        return 0
                    end
                    local room_bet_detail_list = room:get_room_bet_detail_list()
                    for k, v in ipairs(room_bet_detail_list) do
                        v.total_score = get_total_score(v.uid)
                    end
                    local data = {
                        room_bet_detail_list = room_bet_detail_list,
                        round_amount = room:get_round_amount(),
                        round_limit = room:get_round_limit()
                    }
                    skynet.send(".logon", "lua", "sync_anonymous_monitor", data)
                end
            end

            local function loop_timer()
                local flag = room:get_real_open_dice_switch()
                if flag then
                    self.timer = create_timeout(10, function() -- 预留结算时间
                        logger.debug("等待真正的打开骰子....open_dice_count:%d, %s", self.open_dice_count, flag)
                        loop_timer()
                    end)
                else
                    logger.debug("等到了真正的打开骰子....open_dice_count:%d, %s", self.open_dice_count, flag)
                    local blockchains_info = room:get_blockchains_info()
                    seat_mgr:broadcast("on_room_real_open_dice", {
                        blockchains_info = blockchains_info
                    })
                    local settlement_info_list = room:round_settlement()
                    local open_bet_slot_list = room:get_open_bet_slot_list()
                    seat_mgr:broadcast("on_room_settlement", {
                        settlement_info_list = settlement_info_list,
                        open_bet_slot_list = open_bet_slot_list
                    })

                    -- 特殊处理，随时可能取消   
                    sync_settlement_data_to_anonymous()

                    local round_amount = room:get_round_amount()
                    local round_limit = room:get_round_limit()
                    if round_amount >= round_limit then
                        self.timer = create_timeout(10 * 100, function() -- 预留结算时间
                            room:sync_club_chip_to_db()
                            local total_settlement_data = room:total_settlement()
                            local room_create_info = room:fetch_room_create_info()
                            seat_mgr:broadcast("on_room_total_settlement", {
                                total_room_bet_detail_list = total_settlement_data.total_room_bet_detail_list,
                                total_settlement_info_list = total_settlement_data.total_settlement_info_list,
                                room_create_info = room_create_info
                            })
                            room:close_on_total_settlement(total_settlement_data, room_create_info)
                        end)
                    else
                        self.timer = create_timeout(6 * 100, function() -- 预留结算时间
                            room:sync_club_chip_to_db()
                            self:update(shake_dice_conf.GAME_STATE_WAIT_NEXT_ROUND)
                        end)
                    end
                end
            end
            loop_timer()
        end)
    end

    self.state_to_process[shake_dice_conf.GAME_STATE_WAIT_NEXT_ROUND] = function()
        room:round_init()
        local real_uid_list = seat_mgr:real_uid_list()
        for k, uid in ipairs(real_uid_list) do
            seat_mgr:push_message(uid, "on_room_init", {
                room_info = room:info(uid)
            })
        end

        self.timer = create_timeout(shake_dice_conf.TIME_LIMIT_WAIT_NEXT_ROUND * 100, function()
            room:incr_round_amount()
            seat_mgr:broadcast("on_room_round_amount_change", {
                round_amount = room:get_round_amount()
            })
            
            local game_mode = room:get_game_mode()
            if game_mode == shake_dice_conf.GRAB_BRANKER then
                self:update(shake_dice_conf.GAME_STATE_GRAB_BANKER)
            elseif game_mode == shake_dice_conf.FIXED_BRANKER then
                self:update(shake_dice_conf.GAME_STATE_SHAKE_DICE)
            end
        end)
    end

end

function root:register_game_type_to_combination_blockchains_info()
    
    self.game_type_to_combination_blockchains_info[common_conf.GAME_TYPE_YU_XIA_XIE] = function(tmp)
        return room:combination_blockchains_info_of_two(tmp)
    end
    self.game_type_to_combination_blockchains_info[common_conf.GAME_TYPE_TONG_QIAN_JI] = function(tmp)
        return room:combination_blockchains_info_of_three(tmp)
    end
    self.game_type_to_combination_blockchains_info[common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO] = function(tmp)
        return room:combination_blockchains_info_of_four(tmp)
    end

end

function root:init(round_limit)
    -- 特殊处理，随时可能取消
    self.open_award_code = 0
    self.open_award_code_search_start_time_offset = 0
    self.open_award_search_start_block_number = "unmark"
    self.open_award_search_close_block_number = nil
    self.open_award_blockchains_info = nil
    self.tmp_blockchains_info_pool = {}

    self.open_dice_utc_date = ""
    self.open_dice_count = 10000
    self.state_to_process = {}
    self.game_type_to_combination_blockchains_info = {}
    self:register_state_to_process()
    self:register_game_type_to_combination_blockchains_info()
end

function root:update(status)
    -- 特殊处理，随时可能取消
    self.stop_loop_check_time_flag = false

    room:set_status(status)
    local current_time = skynet_time()
    local time_limit = shake_dice_conf.GAME_STATE_TIME_LIMIT_MAP[status]
    local status_finish_time = current_time + time_limit
    room:set_status_finish_time(status_finish_time)

    local round_amount = room:get_round_amount()
    local round_limit = room:get_round_limit()
    local rid = room:get_rid()
    logstr = "update status:%d, round_amount:%d, round_limit:%d, rid:%d, room_number:%s"
    logger.debug(logstr, status, round_amount, round_limit, rid, room:get_room_number())
    game_rooms_db:update_game_room_status_by_rid(rid, status)
    room:club_room_info_change()

    local status_remainder_time = status_finish_time - current_time
    seat_mgr:broadcast("on_room_status_change", {
        status = status,
        status_remainder_time = status_remainder_time
    })

    self.state_to_process[status]()
end

function root:start(status)
    self:update(status)
end

function root:stop()
    local timer = self.timer
	if timer and (not timer.is_timeout()) then
		timer.delete()
    end
    
    -- 特殊处理，随时可能取消
    local special_timer = self.special_timer
    if special_timer and (not special_timer.is_timeout()) then
        special_timer.delete()
    end
end

function root:start_sync_blockchains_info()
    skynet.fork(function ( ... )
        while true do
            local ok, tmp_blockchains_info = room:pop_block_data()
            if ok then

                seat_mgr:broadcast("on_room_sync_open_dice_data", {
                    blockchains_info = room:combination_blockchains_info_of_zore(tmp_blockchains_info)
                })

                -- 特殊处理，随时可能取消
                table.insert(self.tmp_blockchains_info_pool, tmp_blockchains_info)
                if self.open_award_search_start_block_number == "mark" then
                    self.open_award_search_start_block_number = tmp_blockchains_info.block_number
                end

                local game_type = room:get_game_type()
                if room:get_open_dice_switch() then

                    -- 特殊处理，随时可能取消
                    if self.open_award_search_start_block_number ~= "mark" and
                        self.open_award_search_start_block_number ~= "unmark" then
                        local search_open_award_blockchains_info_by_code = function(pool, start, close, c)
                            for k, v in ipairs(pool) do
                                local blockchains_info = v
                                local block_number = v.block_number
                                if block_number >= start and block_number <= close then
                                    for k, v in ipairs(v.open_bet_slot_list_two) do
                                        if v == c then
                                            return blockchains_info
                                        end
                                    end
                                end
                            end
                        end
                        self.open_award_search_close_block_number = tmp_blockchains_info.block_number
                        self.open_award_blockchains_info = search_open_award_blockchains_info_by_code(
                            self.tmp_blockchains_info_pool, self.open_award_search_start_block_number,
                            self.open_award_search_close_block_number, self.open_award_code)
                        if self.open_award_blockchains_info then
                            local search_target_tmp_blockchains_info = function(l, bn)
                                for k, v in ipairs(l) do
                                    if tonumber(v.block_number) == bn then
                                        return v
                                    end
                                end
                                return nil
                            end
                            local real_open_dice_utc_date = common_util:string_time_sub_3s(self.open_award_blockchains_info.utc_date)
                            local real_new_block_number = tonumber(self.open_award_blockchains_info.block_number) - 6
                            local target_tmp_blockchains_info = search_target_tmp_blockchains_info(
                                self.tmp_blockchains_info_pool, real_new_block_number)
                            if target_tmp_blockchains_info then
                                tmp_blockchains_info = target_tmp_blockchains_info
                            else
                                local times_retries = 0
                                local rid = room:get_rid()
                                local room_number = room:get_room_number()
                                local switch_index = 1
                                local ok, res = pcall(http_util.fetch_dfuse_block_data, real_open_dice_utc_date)
                                while not ok do
                                    if switch_index == 1 then
                                        switch_index = 2
                                        ok, res = pcall(http_util.fetch_eosflare_block_data, real_new_block_number)
                                    else
                                        switch_index = 1
                                        ok, res = pcall(http_util.fetch_dfuse_block_data, real_open_dice_utc_date)
                                    end
                                    skynet.sleep(1 * 100)
                                    times_retries = times_retries + 1
                                    local title = "主动获取区块失败报警! 使用渠道:" .. switch_index
                                    local ok, text, title = common_util:alarm_format_block_data_disorder(title, rid, room_number, real_open_dice_utc_date, times_retries)
                                    if ok then http_util.notify_dingtalk(title, text) end
                                end
                                --local title = "主动获取区块成功通知! 使用渠道:" .. switch_index
                                --local ok, text, title = common_util:alarm_format_block_data_disorder(title, rid, room_number, real_open_dice_utc_date, times_retries)
                                --if ok then http_util.notify_dingtalk(title, text) end
                                tmp_blockchains_info = res
                            end
                        end
                    end

                    self.open_dice_count = 0;
                    local blockchains_info = self.game_type_to_combination_blockchains_info[game_type](tmp_blockchains_info)
                    room:set_blockchains_info(blockchains_info)
                    room:set_open_dice_switch(false)
                    room:set_open_dice_blockchains_info(blockchains_info)
                    self.open_dice_utc_date = tmp_blockchains_info.utc_date
                else
                    self.open_dice_count = self.open_dice_count + 1
                    local open_dice_block_number_interval = 6
                    if self.open_dice_count == open_dice_block_number_interval then

                        -- 特殊处理，随时可能取消
                        if self.open_award_search_start_block_number ~= "mark" and
                            self.open_award_search_start_block_number ~= "unmark" then
                            local fetch_blist = function(pool, start, close)
                                local blist = {}
                                for k, v in ipairs(pool) do
                                    local block_number = v.block_number
                                    if block_number then
                                        if block_number >= start and block_number <= close then
                                            table.insert(blist, {b = v.block_number, o = v.open_bet_slot_list_two})
                                        end
                                    else
                                        logger.debug("出错了,区块编号竟然为空:%s", tostring(v))
                                    end
                                end
                                return blist
                            end
                            if type(self.open_award_blockchains_info) ~= "table" then
                                if self.open_award_search_start_block_number and self.open_award_search_close_block_number then
                                    local blist = fetch_blist(
                                        self.tmp_blockchains_info_pool,
                                        self.open_award_search_start_block_number,
                                        self.open_award_search_close_block_number)
                                    local ok, text, title = common_util:alarm_format_open_award("Target not found 通知!",
                                        room:get_rid(), room:get_room_number(), tostring(blist), self.open_award_code)
                                    if ok then
                                        skynet.fork(function (title, text)
                                            http_util.notify_dingtalk(title, text)
                                        end, title, text)
                                    end
                                else
                                    logger.debug("我的天,出错了,区块编号竟然为空:%s, %s",
                                        tostring(self.open_award_search_start_block_number),
                                        tostring(self.open_award_search_close_block_number))
                                end
                            else
                                tmp_blockchains_info = self.open_award_blockchains_info
                            end
                            self.open_award_code = 0
                            self.open_award_code_search_start_time_offset = 0
                            self.open_award_search_start_block_number = "unmark"
                            self.open_award_search_close_block_number = nil
                            self.open_award_blockchains_info = nil
                        end
                        self.tmp_blockchains_info_pool = {}
                        
                        local open_dice_blockchains_info = room:get_open_dice_blockchains_info()
                        local real_open_dice_utc_date = common_util:string_time_add_3s(self.open_dice_utc_date)
                        local new_block_number = tonumber(tmp_blockchains_info.block_number)
                        local old_block_number = tonumber(open_dice_blockchains_info.block_number)
                        local real_new_block_number = old_block_number + open_dice_block_number_interval
                        if real_new_block_number ~= new_block_number then
                            local times_retries = 0
                            local rid = room:get_rid()
                            local room_number = room:get_room_number()
                            local switch_index = 1
                            local ok, res = pcall(http_util.fetch_dfuse_block_data, real_open_dice_utc_date)
                            while not ok do
                                if switch_index == 1 then
                                    switch_index = 2
                                    ok, res = pcall(http_util.fetch_eosflare_block_data, real_new_block_number)
                                else
                                    switch_index = 1
                                    ok, res = pcall(http_util.fetch_dfuse_block_data, real_open_dice_utc_date)
                                end
                                skynet.sleep(1 * 100)
                                times_retries = times_retries + 1
                                local title = "主动获取区块失败报警! 使用渠道:" .. switch_index
                                local ok, text, title = common_util:alarm_format_block_data_disorder(title, rid, room_number, real_open_dice_utc_date, times_retries)
                                if ok then http_util.notify_dingtalk(title, text) end
                            end
                            --local title = "主动获取区块成功通知! 使用渠道:" .. switch_index
                            --local ok, text, title = common_util:alarm_format_block_data_disorder(title, rid, room_number, real_open_dice_utc_date, times_retries)
                            --if ok then http_util.notify_dingtalk(title, text) end
                            tmp_blockchains_info = res
                        end
                        
                        local blockchains_info = self.game_type_to_combination_blockchains_info[game_type](tmp_blockchains_info)
                        room:set_blockchains_info(blockchains_info)
                        room:set_real_open_dice_switch(false)
                        room:set_real_open_dice_blockchains_info(blockchains_info)
                    end
                end
            else
                skynet.sleep(10)
			end
        end
    end)
end

-- 特殊处理，随时可能取消
function root:set_open_award_code(c)
    self.open_award_code = c
    logger.debug("设置编码:%d", self.open_award_code)
end
function root:set_open_award_code_search_start_time_offset(t)
    self.open_award_code_search_start_time_offset = t
    logger.debug("设置偏移值:%d", self.open_award_code_search_start_time_offset)
end

return root
