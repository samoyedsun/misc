local skynet = require "skynet"
local shake_dice_conf = require "server.config.shake_dice_conf"
local seat_mgr = require "server.lualib.seat_mgr"
local bet_dan_mgr = require "server.lualib.bet_dan_mgr"
local bet_bao_zi_mgr = require "server.lualib.bet_bao_zi_mgr"
local bet_lian_chuan_mgr = require "server.lualib.bet_lian_chuan_mgr"
local bet_tao_mgr = require "server.lualib.bet_tao_mgr"
local bet_nuo_mgr = require "server.lualib.bet_nuo_mgr"
local game_db = require "server.common.game_db"
local game_users_db = require "server.common.game_users_db"
local game_rooms_db = require "server.common.game_rooms_db"
local game_clubs_db = require "server.common.game_clubs_db"
local common_conf = require "server.config.common_conf"
local common_util = require "server.common.common_util"
local logger = log4.get_logger("server_lualib_room")

local root = {}

function root:init(param)
	self.game_type = param.game_type
	self.big_game_mode = param.big_game_mode
	self.cid = param.cid
	self.owner_uid = param.owner_uid

	self.round_limit = param.round_limit
	self.user_limit = param.user_limit
	self.game_mode = param.game_mode
	self.bet_slot_limit = param.bet_slot_limit
	self.carry_score = param.carry_score

	self.room_number = param.room_number
	self.rid = param.rid
	self.status = param.status
	self.expend_room_card = param.expend_room_card
	self.bet_tao_switch = param.bet_tao_switch
	self.need_bet_before_nuo = param.need_bet_before_nuo
	
	self.round_amount = 0
	self.status_finish_time = 0
	
	self.shake_dice_switch = false
	self.open_dice_switch = false
	self.real_open_dice_switch = false
	self.open_bet_slot_list = {}
	self.blockchains_info = {}
	self.open_dice_blockchains_info = {}
	self.real_open_dice_blockchains_info = {}
	self.history_blockchains_info_list = {}

	self.uid_to_close_agree = {}
	self.launch_close_time = 0
	self.launch_close_uid = 0
	self.launch_close_timer = nil

	self.uid_to_bet_nuo_times = {}
	self.uid_to_bet_tao_times = {}
	self.shake_dice_flag = false
	self.open_dice_flag = false

	-- 总结算信息
	self.uid_to_settlement_score_list = {}
	self.total_settlement_info_list = {}
	self.total_room_bet_detail_list = {}

	-- 区块链消息队列
	self.block_data_queue = {}

	self:update_game_user_room_card(-self.expend_room_card)
	self:club_room_list_change()
end

function root:get_need_bet_before_nuo()
	return self.need_bet_before_nuo
end

function root:get_cid()
	return self.cid
end

function root:get_game_type()
	return self.game_type
end

function root:get_big_game_mode()
	return self.big_game_mode
end

function root:club_room_list_change()
	local big_game_mode = self:get_big_game_mode()
	if common_util:value_member(common_conf.BIG_GAME_MODE_CLUB_LIST, big_game_mode) then
		skynet.send(".club", "lua", "club_room_list_change", self.cid)
	end
end

function root:club_room_info_change()
	local big_game_mode = self:get_big_game_mode()
	if common_util:value_member(common_conf.BIG_GAME_MODE_CLUB_LIST, big_game_mode) then
        skynet.send(".club", "lua", "club_room_info_change", self:get_cid(), self:get_rid())
    end
end

function root:update_game_user_room_card(room_card)
	local big_game_mode = self:get_big_game_mode()
	if common_util:value_member(common_conf.BIG_GAME_MODE_CLUB_LIST, big_game_mode) then
		local cid = self.cid
		local owner = game_clubs_db:fetch_club_owner_by_cid(cid)
		local owner_uid = owner.uid
		game_users_db:increase_game_user_room_card(room_card, owner_uid)
	else
		local owner_uid = self.owner_uid
		game_users_db:increase_game_user_room_card(room_card, owner_uid)
	end
end

function root:push_block_data(block_data)
	if not self.block_data_queue then
		return
	end 
	table.insert(self.block_data_queue, 1, block_data)
end

function root:pop_block_data()
	if not self.block_data_queue then
		return false
	end
	local block_data = table.remove(self.block_data_queue)
	if not block_data then
		return false
	end
	blockchains = string.split(block_data, " ")
	local open_bet_slot_list_two = blockchains[6]
	local open_bet_slot_list_three = blockchains[7]
	local open_bet_slot_list_four = blockchains[8]

	local open_bet_slot_list_two = common_util:parse_open_bet_slot_list(open_bet_slot_list_two)
	local open_bet_slot_list_three = common_util:parse_open_bet_slot_list(open_bet_slot_list_three)
	local open_bet_slot_list_four = common_util:parse_open_bet_slot_list(open_bet_slot_list_four)
	return true, {
		block_number = blockchains[1],
		block_hash = blockchains[2],
		utc_date = blockchains[3],
		utc_time = blockchains[4],
		utc_timestamp = blockchains[5],
		open_bet_slot_list_two = open_bet_slot_list_two,
		open_bet_slot_list_three = open_bet_slot_list_three,
		open_bet_slot_list_four = open_bet_slot_list_four
	}
end

function root:get_shake_dice_flag()
	return self.shake_dice_flag
end

function root:get_open_dice_flag()
	return self.open_dice_flag
end

function root:mark_shake_dice_flag()
	self.shake_dice_flag = true
end

function root:mark_open_dice_flag()
	self.open_dice_flag = true
end

function root:get_real_open_dice_switch()
	return self.real_open_dice_switch
end

function root:set_real_open_dice_switch(flag)
	self.real_open_dice_switch = flag
end

function root:get_open_dice_switch()
	return self.open_dice_switch
end

function root:set_open_dice_switch(flag)
	self.open_dice_switch = flag
end

function root:bet_nuo_reach_limit_times(uid)
	if (self.uid_to_bet_nuo_times[uid] or 0) >= shake_dice_conf.BET_NUO_LIMIT_TIMES then
		return true
	end
	return false
end

function root:incr_bet_nuo_times(uid)
	self.uid_to_bet_nuo_times[uid] = (self.uid_to_bet_nuo_times[uid] or 0) + 1
end

function root:bet_tao_reach_limit_times(uid)
	if (self.uid_to_bet_tao_times[uid] or 0) >= shake_dice_conf.BET_TAO_LIMIT_TIMES then
		return true
	end
	return false
end

function root:incr_bet_tao_times(uid)
	self.uid_to_bet_tao_times[uid] = (self.uid_to_bet_tao_times[uid] or 0) + 1
end

function root:combination_blockchains_info_of_two(blockchains_info)
	return {
		block_number = blockchains_info.block_number,
		block_hash = blockchains_info.block_hash,
		utc_time = blockchains_info.utc_time,
		open_bet_slot_list = blockchains_info.open_bet_slot_list_two
	}
end

function root:combination_blockchains_info_of_three(blockchains_info)
	return {
		block_number = blockchains_info.block_number,
		block_hash = blockchains_info.block_hash,
		utc_time = blockchains_info.utc_time,
		open_bet_slot_list = blockchains_info.open_bet_slot_list_three
	}
end

function root:combination_blockchains_info_of_four(blockchains_info)
	return {
		block_number = blockchains_info.block_number,
		block_hash = blockchains_info.block_hash,
		utc_time = blockchains_info.utc_time,
		open_bet_slot_list = blockchains_info.open_bet_slot_list_four
	}
end

function root:combination_blockchains_info_of_zore(blockchains_info)
	return {
		block_number = blockchains_info.block_number,
		block_hash = blockchains_info.block_hash,
		utc_time = blockchains_info.utc_time,
		open_bet_slot_list = {}
	}
end

function root:set_launch_close_timer(timer)
	self.launch_close_timer = timer
end

function root:get_launch_close_timer()
	return self.launch_close_timer
end

function root:set_launch_close_time(time)
	self.launch_close_time = time
end

function root:get_launch_close_time()
	return self.launch_close_time
end

function root:set_launch_close_uid(uid)
	self.launch_close_uid = uid
end

function root:get_launch_close_uid()
	return self.launch_close_uid
end

function root:reset_launch_close()
	self.uid_to_close_agree = {}
	self.launch_close_time = 0
	self.launch_close_uid = 0
	local timer = self.launch_close_timer
	if timer and (not timer.is_timeout()) then
		timer.delete()
	end
end

function root:round_init()
	self.open_bet_slot_list = {}
	self.blockchains_info = {}
	self.open_dice_blockchains_info = {}
	self.real_open_dice_blockchains_info = {}
	self.uid_to_bet_nuo_times = {}
	self.uid_to_bet_tao_times = {}
	self.shake_dice_flag = false
	self.open_dice_flag = false
	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in ipairs(real_uid_list) do
		bet_dan_mgr:reset(uid)
		bet_bao_zi_mgr:reset(uid)
		bet_lian_chuan_mgr:reset(uid)
		bet_tao_mgr:reset(uid)
		bet_nuo_mgr:reset(uid)
	end
end

function root:fetch_room_create_info()
	local current_time = skynet_time()
	return {
		room_number = self.room_number,
		expend_room_card = self.expend_room_card,
		room_close_time = current_time,
		game_type = self.game_type,
		round_limit = self.round_limit,
		user_limit = self.user_limit,
		game_mode = self.game_mode,
		bet_slot_limit = self.bet_slot_limit,
		carry_score = self.carry_score,
		bet_tao_switch = self.bet_tao_switch,
		big_game_mode = self:get_big_game_mode(),
		cid = self:get_cid(),
		rid = self:get_rid()
	}
end

function root:save_room_record(total_settlement_data, room_create_info)
	local total_settlement_data = total_settlement_data or self:total_settlement()
	local total_settlement_info_list = total_settlement_data.total_settlement_info_list
	local total_room_bet_detail_list = total_settlement_data.total_room_bet_detail_list
	local total_score_info_list = {}
	for k, total_settlement_info in ipairs(total_settlement_info_list) do
		table.insert(total_score_info_list, {
			uid = total_settlement_info.uid,
			nick_name = total_settlement_info.nick_name,
			total_score = total_settlement_info.total_score
		})
	end
	local room_create_info = room_create_info or self:fetch_room_create_info()
	local content = {
		total_score_info_list = total_score_info_list,
		total_settlement_info_list = total_settlement_info_list,
		total_room_bet_detail_list = total_room_bet_detail_list
	}
	local content = cjson_encode(content)
	local function get_self_score(uid)
		local total_score = 0
		for k, info in ipairs(total_score_info_list) do
			if info.uid == uid then
				total_score = info.total_score
			end
		end
		return total_score
	end

	local total_join_uid_list = seat_mgr:fetch_total_join_uid_list()
	for k, uid in ipairs(total_join_uid_list) do
		local total_score = get_self_score(uid)
		game_db:insert_user_room_records(uid, total_score, room_create_info, content)
	end
end

function root:close_common()
	self:set_status(shake_dice_conf.GAME_STATE_CLOSE)
	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in pairs(real_uid_list) do
		--skynet.send(".club", "lua", "update_club_chat_member", uid)
		--skynet.send(".club", "lua", "update_single_chat_member", uid)
	end
	local rid = self:get_rid()
	game_users_db:clear_game_user_rid(rid)
	game_rooms_db:delete_game_rooms(rid)
	game_db:resolve_use_room_number_rid(self.room_number)
	self:club_room_list_change()
	skynet.timeout(1 * 100, function ()
		logger.info("kill %08x, rid:%d", skynet.self(), rid)
		skynet.exit()
	end)
end

function root:close_on_stop_operations()
	local status = self:get_status()
	if status ~= shake_dice_conf.GAME_STATE_WAIT_PLAY then
		return
	end
	local owner_uid = self:get_owner_uid()
	self:update_game_user_room_card(self.expend_room_card)

	local rid = self:get_rid()
	local finish_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
	game_db:update_room_record(rid, common_conf.UNEXPENDED, common_conf.ROOM_CLOSE, finish_date)
	
	seat_mgr:broadcast("on_room_stop_operations", {
		tips = common_conf.STOP_OPERATIONS_TIPS
	})
	self:close_common()
end

function root:close_on_total_settlement(total_settlement_data, room_create_info)
	local owner_uid = self:get_owner_uid()
	local round_amount = self:get_round_amount()
	if round_amount <= 1 then
		self:update_game_user_room_card(self.expend_room_card)

		local rid = self:get_rid()
		local finish_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
		game_db:update_room_record(rid, common_conf.UNEXPENDED, common_conf.ROOM_CLOSE, finish_date)
	else
		self:save_room_record(total_settlement_data, room_create_info)

		local rid = self:get_rid()
		local finish_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
		game_db:update_room_record(rid, common_conf.EXPENDED, common_conf.ROOM_CLOSE, finish_date)
	end
	self:close_common()
end

function root:close()
	local owner_uid = self:get_owner_uid()
	local round_amount = self:get_round_amount()
	if round_amount <= 1 then
		self:update_game_user_room_card(self.expend_room_card)

		local rid = self:get_rid()
		local finish_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
		game_db:update_room_record(rid, common_conf.UNEXPENDED, common_conf.ROOM_CLOSE, finish_date)
	else
		self:save_room_record()

		local rid = self:get_rid()
		local finish_date = os.date("%Y-%m-%d %H:%M:%S", skynet_time())
		game_db:update_room_record(rid, common_conf.EXPENDED, common_conf.ROOM_CLOSE, finish_date)
	end
	
	seat_mgr:broadcast("on_room_close", {
		round_amount = self:get_round_amount(),
		round_limit = self:get_round_limit(),
		room_number = self:get_room_number()
	})
	self:close_common()
end

function root:is_bet(uid)
	local bet_dan_empty = bet_dan_mgr:empty(uid)
	local bet_bao_zi_empty = bet_bao_zi_mgr:empty(uid)
	local bet_lian_chuan_empty = bet_lian_chuan_mgr:empty(uid)
	local bet_tao_empty = bet_tao_mgr:empty(uid)
	local bet_nuo_empty = bet_nuo_mgr:empty(uid)
	if (not bet_dan_empty) or
		(not bet_bao_zi_empty) or
		(not bet_lian_chuan_empty) or
		(not bet_tao_empty) or
		(not bet_nuo_empty) then
		return true
	end
	return false
end

function root:is_affirm(uid)
	local affirm = self.uid_to_close_agree[uid] 
	if not affirm then
		return false
	end
	return true
end

function root:is_all_agree()
	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in pairs(real_uid_list) do
		local affirm = self.uid_to_close_agree[uid] 
		if not affirm then
			return false
		end
	end
	return true
end

function root:room_close_info()
	local close_agree_info_list = {}

	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in pairs(real_uid_list) do
		if uid ~= self.launch_close_uid then
			local game_user = game_users_db:fetch_game_user_by_uid(uid)
			local nick_name = game_user.nick_name
			if self.uid_to_close_agree[uid] then
				table.insert(close_agree_info_list, {
					nick_name = nick_name,
					close_agree = shake_dice_conf.CLOSE_AGREE
				})
			else
				table.insert(close_agree_info_list, {
					nick_name = nick_name,
					close_agree = shake_dice_conf.CLOSE_DISAGREE
				})
			end
		end
	end
	
	local nick_name = ""
	if self.launch_close_uid ~= 0 then
		local uid = self.launch_close_uid
		local game_user = game_users_db:fetch_game_user_by_uid(uid)
		nick_name = game_user.nick_name
	end
	local finish_close_time = self.launch_close_time + shake_dice_conf.CLOSE_ROOM_TIME_LIMIT
	local current_time = skynet_time()
	local launch_close_remainder_time = finish_close_time - current_time

	return {
		close_agree_info_list = close_agree_info_list,
		launch_close_remainder_time = launch_close_remainder_time,
		launch_close_nick_name = nick_name
	}
end

function root:close_agree(uid)
	self.uid_to_close_agree[uid] = true
end

function root:get_bet_slot_limit()
	return self.bet_slot_limit
end

function root:get_carry_score()
	return self.carry_score
end

function root:get_game_mode()
	return self.game_mode
end

function root:get_owner_uid()
	return self.owner_uid
end

function root:owner(uid)
	return self.owner_uid == uid
end

function root:get_round_limit()
	return self.round_limit
end

function root:incr_round_amount()
	local rid = self:get_rid()
    local round_amount = self.round_amount + 1
	game_rooms_db:update_game_room_round_amount_by_rid(rid, round_amount)
	self.round_amount = round_amount
	self:club_room_info_change()
end

function root:get_round_amount()
    return self.round_amount
end

function root:banker(uid)
	local banker = seat_mgr:banker(uid)
	if not banker then
		return false
	end
    return true
end

function root:get_rid()
    return self.rid
end

function root:get_room_number()
    return self.room_number
end

function root:set_status(status)
	self.status = status
end

function root:set_status_finish_time(time)
	self.status_finish_time = time
end

function root:get_status()
	return self.status
end

function root:del_tmp_open_bet_slot_list()
	self.tmp_open_bet_slot_list = nil
end

function root:set_tmp_open_bet_slot_list(tmp)
	self.tmp_open_bet_slot_list = tmp
end

function root:get_tmp_open_bet_slot_list()
	return self.tmp_open_bet_slot_list
end
--

function root:get_open_bet_slot_list()
	if self:get_tmp_open_bet_slot_list() then
		return self:get_tmp_open_bet_slot_list()
	end
	return self.open_bet_slot_list
end

function root:get_blockchains_info()
	local blockchains_info = self.blockchains_info
	if self:get_tmp_open_bet_slot_list() then
		blockchains_info.open_bet_slot_list = self:get_tmp_open_bet_slot_list()
	end
	return blockchains_info
end

function root:set_blockchains_info(blockchains_info)
	self.blockchains_info = blockchains_info
	self.open_bet_slot_list = blockchains_info.open_bet_slot_list
end

function root:get_open_dice_blockchains_info()
	local blockchains_info = self.open_dice_blockchains_info
	if self:get_tmp_open_bet_slot_list() then
		blockchains_info.open_bet_slot_list = self:get_tmp_open_bet_slot_list()
	end
	return blockchains_info
end

function root:set_open_dice_blockchains_info(blockchains_info)
	self.open_dice_blockchains_info = blockchains_info
end

function root:get_real_open_dice_blockchains_info()
	local blockchains_info = self.real_open_dice_blockchains_info
	if self:get_tmp_open_bet_slot_list() then
		blockchains_info.open_bet_slot_list = self:get_tmp_open_bet_slot_list()
	end
	return blockchains_info
end

function root:set_real_open_dice_blockchains_info(blockchains_info)
	self.real_open_dice_blockchains_info = blockchains_info
end

function root:round_settlement()
	local banker_score = 0
	local uid_to_score = {}
	local uid_to_return_self_amount = {}
	local uid_to_give_banker_amount = {}
	--local uid_to_return_banker_amount = {}
	--local uid_to_give_self_amount = {}
	local game_type = self.game_type
	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in ipairs(real_uid_list) do
		if not seat_mgr:banker(uid) then
			local settlement_info = bet_dan_mgr:round_settlement(uid, self:get_open_bet_slot_list(), game_type)
			banker_score = banker_score + settlement_info.banker_win_amount
			uid_to_score[uid] = (uid_to_score[uid] or 0) + settlement_info.self_win_amount
			uid_to_return_self_amount[uid] = (uid_to_return_self_amount[uid] or 0) + settlement_info.return_self_amount
			uid_to_give_banker_amount[uid] = (uid_to_give_banker_amount[uid] or 0) + settlement_info.give_banker_amount
		end
	end
	for k, uid in ipairs(real_uid_list) do
		if not seat_mgr:banker(uid) then
			local settlement_info = bet_bao_zi_mgr:round_settlement(uid, self:get_open_bet_slot_list(), game_type)
			banker_score = banker_score + settlement_info.banker_win_amount
			uid_to_score[uid] = (uid_to_score[uid] or 0) + settlement_info.self_win_amount
			uid_to_return_self_amount[uid] = (uid_to_return_self_amount[uid] or 0) + settlement_info.return_self_amount
			uid_to_give_banker_amount[uid] = (uid_to_give_banker_amount[uid] or 0) + settlement_info.give_banker_amount
		end
	end
	for k, uid in ipairs(real_uid_list) do
		if not seat_mgr:banker(uid) then
			local settlement_info = bet_lian_chuan_mgr:round_settlement(uid, self:get_open_bet_slot_list(), game_type)
			banker_score = banker_score + settlement_info.banker_win_amount
			uid_to_score[uid] = (uid_to_score[uid] or 0) + settlement_info.self_win_amount
			uid_to_return_self_amount[uid] = (uid_to_return_self_amount[uid] or 0) + settlement_info.return_self_amount
			uid_to_give_banker_amount[uid] = (uid_to_give_banker_amount[uid] or 0) + settlement_info.give_banker_amount
		end
	end
	for k, uid in ipairs(real_uid_list) do
		if not seat_mgr:banker(uid) then
			local settlement_info = bet_nuo_mgr:round_settlement(uid, self:get_open_bet_slot_list(), game_type)
			banker_score = banker_score + settlement_info.banker_win_amount
			uid_to_score[uid] = (uid_to_score[uid] or 0) + settlement_info.self_win_amount
		end
	end
	for k, uid in ipairs(real_uid_list) do
		if not seat_mgr:banker(uid) then
			local settlement_info = bet_tao_mgr:round_settlement(uid, self:get_open_bet_slot_list(), game_type)
			banker_score = banker_score + settlement_info.banker_win_amount
			uid_to_score[uid] = (uid_to_score[uid] or 0) + settlement_info.self_win_amount
			--uid_to_return_banker_amount[uid] = (uid_to_return_banker_amount[uid] or 0) + settlement_info.return_banker_amount
			--uid_to_give_self_amount[uid] = (uid_to_give_self_amount[uid] or 0) + settlement_info.give_self_amount
		end
	end

	-- 合并庄家的分数到uid_to_score
	local banker_uid = seat_mgr:get_banker_uid()
	uid_to_score[banker_uid] = banker_score

	for k, uid in ipairs(real_uid_list) do
		local score = seat_mgr:get_score(uid)
		score = score + uid_to_score[uid]
		if seat_mgr:banker(uid) then
			--score = score + (uid_to_return_banker_amount[uid] or 0)
		else
			score = score + (uid_to_return_self_amount[uid] or 0)
		end
		seat_mgr:set_score(uid, score)
		
		seat_mgr:broadcast("on_room_score_change", {
			seat_info = seat_mgr:seat_info(uid)
		})
	end


	local settlement_info_list = {}
	for uid, score in pairs(uid_to_score) do
		if seat_mgr:banker(uid) then
			--score = score - (uid_to_give_self_amount[uid] or 0)
		else
			score = score - (uid_to_give_banker_amount[uid] or 0)
		end
		local game_user = seat_mgr:get_game_user(uid)
		local seat_info = seat_mgr:seat_info(uid)
		table.insert(settlement_info_list, {
			avatar = game_user.avatar,
			nick_name = game_user.nick_name,
			score = score,
			sid = seat_info.sid,
			banker = seat_info.banker,
			uid = uid
		})
	end

	table.insert(self.history_blockchains_info_list, {
		open_dice_blockchains_info = self:get_open_dice_blockchains_info(),
		real_open_dice_blockchains_info = self:get_real_open_dice_blockchains_info()
	})

	-- 记录总结算信息
	local function get_settlement_info(uid)
		local sid = seat_mgr:get_sid(uid)
		for k, settlement_info in ipairs(settlement_info_list) do
			if settlement_info.sid == sid then
				return settlement_info
			end
		end
	end
	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in ipairs(real_uid_list) do
		local settlement_info = get_settlement_info(uid)
		local settlement_score_list = self.uid_to_settlement_score_list[uid]
		local settlement_score_list = settlement_score_list or {}

		local game_user = seat_mgr:get_game_user(uid)
		local seat_info = seat_mgr:seat_info(uid)
		table.insert(settlement_score_list, {
			round_amount = self.round_amount,
			score = settlement_info.score,

			--为了总结算能获取到哪些不再房间的人的信息而额外加的
			nick_name = game_user.nick_name,
			banker = seat_info.banker,
			avatar = game_user.avatar
		})
		self.uid_to_settlement_score_list[uid] = settlement_score_list
	end
	local room_bet_detail_list = self:get_room_bet_detail_list()
	table.insert(self.total_room_bet_detail_list, {
		round_amount = self.round_amount,
		room_bet_detail_list = room_bet_detail_list,
		open_dice_blockchains_info = self:get_open_dice_blockchains_info(),
		real_open_dice_blockchains_info = self:get_real_open_dice_blockchains_info()
	})

	return settlement_info_list
end

-- 每次结算同步所有人的筹码到数据库
function root:sync_club_chip_to_db()
	local big_game_mode = self:get_big_game_mode()
	if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
		local real_uid_list = seat_mgr:real_uid_list()
		for k, uid in pairs(real_uid_list) do
			local cid = self:get_cid()
			local club_chip = seat_mgr:get_score(uid)
			game_clubs_db:update_club_member_club_chip(club_chip, cid, uid)
			skynet.send(".club", "lua", "update_club_member_info", cid, uid)
		end
	end
end

function root:total_settlement()
	local total_settlement_info_list = {}
	for uid, settlement_score_list in pairs(self.uid_to_settlement_score_list) do
		local nick_name = ""
		local banker = ""
		local avatar = ""
		local total_score = 0
		for k, settlement_score in pairs(settlement_score_list) do
			total_score = total_score + settlement_score.score

			--为了总结算能获取到哪些不再房间的人的信息而额外加的
			nick_name = settlement_score.nick_name
			banker = settlement_score.banker
			avatar = settlement_score.avatar
		end
		table.insert(total_settlement_info_list, {
			uid = uid,
			nick_name = nick_name,
			total_score = total_score,
			settlement_score_list = settlement_score_list,
			banker = banker,
			avatar = avatar
		})
	end
	return {
		total_room_bet_detail_list = self.total_room_bet_detail_list,
		total_settlement_info_list = total_settlement_info_list
	}
end

function root:get_room_bet_detail_list()
	local room_bet_detail_list = {}
	local real_uid_list = seat_mgr:real_uid_list()
	for k, uid in ipairs(real_uid_list) do
		local bet_detail_list = {}

		local bet_slot_detail_list = bet_dan_mgr:get_bet_slot_detail_list(uid)
		table.insert(bet_detail_list, {
			bet_type = shake_dice_conf.BET_TYPE_DAN,
			bet_slot_detail_list = bet_slot_detail_list
		})
		local bet_slot_detail_list = bet_bao_zi_mgr:get_bet_slot_detail_list(uid)
		table.insert(bet_detail_list, {
			bet_type = shake_dice_conf.BET_TYPE_BAO_ZI,
			bet_slot_detail_list = bet_slot_detail_list
		})
		local bet_slot_detail_list = bet_lian_chuan_mgr:get_bet_slot_detail_list(uid)
		table.insert(bet_detail_list, {
			bet_type = shake_dice_conf.BET_TYPE_LIAN_CHUAN,
			bet_slot_detail_list = bet_slot_detail_list
		})
		local bet_slot_detail_list = bet_nuo_mgr:get_bet_slot_detail_list(uid)
		table.insert(bet_detail_list, {
			bet_type = shake_dice_conf.BET_TYPE_NUO,
			bet_slot_detail_list = bet_slot_detail_list
		})
		local bet_slot_detail_list = bet_tao_mgr:get_bet_slot_detail_list(uid)
		table.insert(bet_detail_list, {
			bet_type = shake_dice_conf.BET_TYPE_TAO,
			bet_slot_detail_list = bet_slot_detail_list
		})

		local game_user = seat_mgr:get_game_user(uid)
		table.insert(room_bet_detail_list, {
			uid = game_user.uid,
			nick_name = game_user.nick_name,
			avatar = game_user.avatar,
			bet_detail_list = bet_detail_list
		})
	end
	return room_bet_detail_list
end

function root:info(uid)
    local current_time = skynet_time()
	local status_remainder_time = self.status_finish_time - current_time

    return {
		room_number = self.room_number,
		rid = self:get_rid(),
		round_amount = self.round_amount,
		round_limit = self.round_limit,
		status = self.status,
		status_remainder_time = status_remainder_time,
		seat_info_list = seat_mgr:seat_info_list(),
		bet_slot_info_list = self:get_bet_slot_info_list(uid),
		room_close_info = self:room_close_info(),
		history_blockchains_info_list = self.history_blockchains_info_list,
		room_bet_detail_list = self:get_room_bet_detail_list(),
		user_limit = self.user_limit,
		bet_tao_switch = self.bet_tao_switch,
		bet_slot_limit = self:get_bet_slot_limit(),
		carry_score = self.carry_score,
		expend_room_card = self.expend_room_card,
		game_type = self.game_type,
		game_mode = self.game_mode,
		owner_uid = self.owner_uid,
		big_game_mode = self:get_big_game_mode(),
		cid = self:get_cid()
    }
end

-- 获取某个位置押单的钱 + 挪到那个位置的钱 - 从那里挪走的钱 + 讨到那个位置的钱
function root:get_bet_slot_real_total_amount(slot)
	local dan_target_bet_slot_chip_total_amount = bet_dan_mgr:get_bet_slot_chip_total_amount(slot)
	local bet_slot_real_total_amount = dan_target_bet_slot_chip_total_amount

	local nuo_target_bet_slot_chip_total_amount = bet_nuo_mgr:get_target_bet_slot_chip_total_amount(slot)
	local nuo_source_bet_slot_chip_total_amount = bet_nuo_mgr:get_source_bet_slot_chip_total_amount(slot)
	local bet_slot_real_total_amount = bet_slot_real_total_amount + nuo_target_bet_slot_chip_total_amount
	local bet_slot_real_total_amount = bet_slot_real_total_amount - nuo_source_bet_slot_chip_total_amount

	local tao_target_bet_slot_chip_total_amount = bet_tao_mgr:get_target_bet_slot_chip_total_amount(slot)
	local bet_slot_real_total_amount = bet_slot_real_total_amount + tao_target_bet_slot_chip_total_amount

	return bet_slot_real_total_amount
end

function root:get_bet_slot_info_list(uid, curtail)
	local bet_slot_info_list = bet_dan_mgr:get_bet_slot_info_list(uid)
	for k, bet_slot_info in ipairs(bet_slot_info_list) do
		local bet_slot = bet_slot_info.bet_slot
		local bet_slot_real_total_amount = self:get_bet_slot_real_total_amount(bet_slot)
		bet_slot_info.bet_slot_chip_total_amount = bet_slot_real_total_amount
		if curtail then
			bet_slot_info.bet_slot_chip_total_list = nil
		end
	end
	return bet_slot_info_list
end

function root:get_real_score(uid)
	local big_game_mode = self:get_big_game_mode()

	local win_multiple = 1
	if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
		win_multiple = win_multiple + shake_dice_conf.WIN_MULTIPLE_NUO_TWO
	else
		win_multiple = 0
	end
	local nuo_bet_slot_chip_total_amount = bet_nuo_mgr:get_bet_slot_chip_total_amount(uid)
	local nuo_bet_slot_chip_freeze_amount = nuo_bet_slot_chip_total_amount * win_multiple


	local win_multiple = 1
	if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
		win_multiple = win_multiple + shake_dice_conf.WIN_MULTIPLE_TAO_TWO
	else
		win_multiple = 0
	end
	local tao_bet_slot_chip_total_amount = bet_tao_mgr:get_bet_slot_chip_total_amount(uid)
	local tao_bet_slot_chip_freeze_amount = tao_bet_slot_chip_total_amount * win_multiple

	local real_score = seat_mgr:get_score(uid)
	local real_score = real_score - nuo_bet_slot_chip_freeze_amount
	local real_score = real_score - tao_bet_slot_chip_freeze_amount
	return real_score
end

function root:calc_bet_dan_limit(uid, slot)
	local bet_slot_limit = self:get_bet_slot_limit()
	local score = self:get_real_score(uid)

	local big_game_mode = self:get_big_game_mode()
	local carry_score = self:get_carry_score()
	local bet_slot_real_total_amount = self:get_bet_slot_real_total_amount(slot)
	local limit = bet_slot_limit - bet_slot_real_total_amount
	if score < limit and (carry_score ~= common_conf.CARRY_SCORE_INFINITE or big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP) then
		limit = score
	end
	return limit
end

function root:calc_bet_bao_zi_limit(uid, slot)
	local bet_slot_limit = self:get_bet_slot_limit()
	local score = self:get_real_score(uid)

	local big_game_mode = self:get_big_game_mode()
	local carry_score = self:get_carry_score()
	local bet_slot_limit = math.floor(bet_slot_limit * 10 / 100)
	local bet_slot_chip_total_amount = bet_bao_zi_mgr:get_bet_slot_chip_amount(uid, slot)
	local limit = bet_slot_limit - bet_slot_chip_total_amount
	if score < limit and (carry_score ~= common_conf.CARRY_SCORE_INFINITE or big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP) then
		limit = score
	end
	return limit
end

function root:calc_bet_lian_chuan_limit(uid, slot_list)
	local bet_slot_limit = self:get_bet_slot_limit()
	local score = self:get_real_score(uid)

	local big_game_mode = self:get_big_game_mode()
	local carry_score = self:get_carry_score()
	local bet_slot_limit = math.floor(bet_slot_limit * 20 / 100)
	local bet_slot_chip_total_amount = bet_lian_chuan_mgr:get_bet_slot_chip_amount(uid, slot_list)
	local limit = bet_slot_limit - bet_slot_chip_total_amount
	if score < limit and (carry_score ~= common_conf.CARRY_SCORE_INFINITE or big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP) then
		limit = score
	end
	return limit
end

function root:calc_bet_nuo_limit(uid, slot_list)
	local bet_source_slot_real_total_amount = self:get_bet_slot_real_total_amount(slot_list[1])
	local score = self:get_real_score(uid)

	local big_game_mode = self:get_big_game_mode()
	local carry_score = self:get_carry_score()
	local nuo_target_bet_slot_chip_limit = 0
	if (carry_score ~= common_conf.CARRY_SCORE_INFINITE or big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP) then
		if (score * 20 / 100) >= (bet_source_slot_real_total_amount * 80 / 100) then
			nuo_target_bet_slot_chip_limit = (bet_source_slot_real_total_amount * 80 / 100)
		elseif (score * 20 / 100) < (bet_source_slot_real_total_amount * 80 / 100) then
			nuo_target_bet_slot_chip_limit = (score * 20 / 100)
		end
	else
		nuo_target_bet_slot_chip_limit = (bet_source_slot_real_total_amount * 80 / 100)
	end
	local nuo_target_bet_slot_chip_limit = math.floor(nuo_target_bet_slot_chip_limit)

	-- 自己还可以挪的数量 = nuo_target_bet_slot_chip_limit - 自己已经挪的
	local bet_slot_chip_amount = bet_nuo_mgr:get_bet_slot_chip_amount(uid, slot_list)
	local can_nuo_target_bet_slot_amount = nuo_target_bet_slot_chip_limit - bet_slot_chip_amount
	-- 目标位置还可以下注数量 = 单位置下注限制 - 目标位置真正存在的数量
	local bet_slot_limit = self:get_bet_slot_limit()
	local bet_target_slot_real_total_amount = self:get_bet_slot_real_total_amount(slot_list[2])
	local can_bet_target_bet_slot_amount = bet_slot_limit - bet_target_slot_real_total_amount
	-- 如果 (目标位置还可以下注数量 > 自己还可以挪的数量) 则 (limit = [自己还可以挪的数量]) 否则 (limit = [自己还可以挪的数量-目标位置还可以下注数量])
	local limit = 0
	if can_bet_target_bet_slot_amount > can_nuo_target_bet_slot_amount then
		limit = can_nuo_target_bet_slot_amount
	else
		limit = can_bet_target_bet_slot_amount
	end
	if limit < 0 then
		limit = 0
	end
	return limit
end

function root:calc_bet_tao_limit(uid, slot_list)
	local bet_slot_limit = self:get_bet_slot_limit()
	local score = self:get_real_score(uid)

	local big_game_mode = self:get_big_game_mode()
	local carry_score = self:get_carry_score()
	local tao_target_bet_slot_chip_limit = 0
	if (carry_score ~= common_conf.CARRY_SCORE_INFINITE or big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP) then
		if (score * 20 / 100) >= bet_slot_limit then
			tao_target_bet_slot_chip_limit = bet_slot_limit * 10 / 100
		elseif (score * 20 / 100) < bet_slot_limit then
			if (score * 20 / 100) >= (bet_slot_limit * 10 / 100) then
				tao_target_bet_slot_chip_limit = bet_slot_limit * 10 / 100
			else
				tao_target_bet_slot_chip_limit = (score * 20 / 100)
			end
		end
	else
		tao_target_bet_slot_chip_limit = bet_slot_limit * 10 / 100
	end
	local tao_target_bet_slot_chip_limit = math.floor(tao_target_bet_slot_chip_limit)

	-- 自己还可以讨的数量 = tao_target_bet_slot_chip_limit - 自己已经讨的
	local bet_slot_chip_amount = bet_tao_mgr:get_bet_slot_chip_amount(uid, slot_list)
	local can_tao_target_bet_slot_amount = tao_target_bet_slot_chip_limit - bet_slot_chip_amount
	-- 目标位置还可以下注数量 = 单位置下注限制 - 目标位置真正存在的数量
	local bet_target_slot_real_total_amount = self:get_bet_slot_real_total_amount(slot_list[2])
	local can_bet_target_bet_slot_amount = bet_slot_limit - bet_target_slot_real_total_amount
	-- 如果 (目标位置还可以下注数量 > 自己还可以讨的数量) 则 (limit = 自己还可以讨的数量) 否则 (limit = 目标位置还可以下注数量)
	local limit = 0
	if can_bet_target_bet_slot_amount > can_tao_target_bet_slot_amount then
		limit = can_tao_target_bet_slot_amount
	else
		limit = can_bet_target_bet_slot_amount
	end
	if limit < 0 then
		limit = 0
	end
	return limit
end

return root