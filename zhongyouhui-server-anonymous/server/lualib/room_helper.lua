local skynet = require "skynet"
local code = require "server.config.code"
local shake_dice_conf = require "server.config.shake_dice_conf"
local seat_mgr = require "server.lualib.seat_mgr"
local state_machine = require "server.lualib.state_machine"
local bet_dan_mgr = require "server.lualib.bet_dan_mgr"
local bet_bao_zi_mgr = require "server.lualib.bet_bao_zi_mgr"
local bet_lian_chuan_mgr = require "server.lualib.bet_lian_chuan_mgr"
local bet_nuo_mgr = require "server.lualib.bet_nuo_mgr"
local bet_tao_mgr = require "server.lualib.bet_tao_mgr"
local room = require "server.lualib.room"
local game_db = require "server.common.game_db"
local game_users_db = require "server.common.game_users_db"
local game_rooms_db = require "server.common.game_rooms_db"
local game_clubs_db = require "server.common.game_clubs_db"
local common_util = require "server.common.common_util"
local http_util = require "server.common.http_util"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_lualib_room_helper")

local CMD = {}

function CMD.create(param)
	seat_mgr:init(param.user_limit)
	state_machine:init()
	bet_dan_mgr:init()
	bet_bao_zi_mgr:init()
	bet_lian_chuan_mgr:init()
	bet_tao_mgr:init()
	bet_nuo_mgr:init()
	room:init(param)
	state_machine:start_sync_blockchains_info()
	
	state_machine:start(shake_dice_conf.GAME_STATE_WAIT_PLAY)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.join(param)
	local uid = param.uid
	local game_user = param.game_user
	local user_net = param.user_net

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:full()
	if ok then
		return {code = code.ERROR_NO_EMPTY_SEAT, err = code.ERROR_NO_EMPTY_SEAT_MSG}
	end
	local owner_uid = room:get_owner_uid()
	local game_mode = room:get_game_mode()
	local big_game_mode = room:get_big_game_mode()
	if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
		local cid = room:get_cid()
		local member = game_clubs_db:fetch_club_member(cid, uid)
		local carry_score = member.club_chip
		if game_mode == shake_dice_conf.FIXED_BRANKER and owner_uid == uid then
			seat_mgr:join_seat(uid, carry_score, game_user, user_net)
			seat_mgr:update_banker(uid)
		else
			seat_mgr:join_seat(uid, carry_score, game_user, user_net)
		end
	else
		if game_mode == shake_dice_conf.FIXED_BRANKER and owner_uid == uid then
			local carry_score = 0
			seat_mgr:join_seat(uid, carry_score, game_user, user_net)
			seat_mgr:update_banker(uid)
		else
			local carry_score = room:get_carry_score()
			seat_mgr:join_seat(uid, carry_score, game_user, user_net)
		end
	end
	local bet_slot_list = shake_dice_conf.BET_SLOT_LIST
	local game_type = room:get_game_type()
	if game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
		bet_slot_list = shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST
	end
	local double_combined_slot_list = common_util:fetch_combined(bet_slot_list)
	bet_dan_mgr:alloc(uid, bet_slot_list)
	bet_bao_zi_mgr:alloc(uid, bet_slot_list)
	bet_lian_chuan_mgr:alloc(uid, double_combined_slot_list)
	bet_tao_mgr:alloc(uid, double_combined_slot_list)
	bet_nuo_mgr:alloc(uid, double_combined_slot_list)
	
    seat_mgr:broadcast("on_room_join", {
		seat_info = seat_mgr:seat_info(uid)
	}, uid)

	local rid = room:get_rid()
	local user_amount = seat_mgr:user_amount()
	game_users_db:update_game_user_rid(uid, rid)
    --skynet.send(".club", "lua", "update_club_chat_member", uid)
    --skynet.send(".club", "lua", "update_single_chat_member", uid)
	game_rooms_db:update_game_room_user_amount_by_rid(rid, user_amount)
	room:club_room_info_change()

    local data = {
        room_info = room:info(uid)
    }
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.info(uid, user_net)
	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	seat_mgr:set_user_net(uid, user_net)
	seat_mgr:online(uid)
    seat_mgr:broadcast("on_room_join", {
		seat_info = seat_mgr:seat_info(uid)
	}, uid)
	
    local data = {
        room_info = room:info(uid)
    }
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.chat(uid, chat_info)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local words = chat_info.words
	if type(words) == "string" and string.sub(words, 1, 1) == "o" then
		local pos = string.find(words, " ")
		local cmd = nil
		local params = {}
		if not pos then
			cmd = string.sub(words, 2, string.len(words))
		else
			cmd = string.sub(words, 2, pos - 1)
			tmp = string.sub(words, pos + 1, string.len(words))
			for w in string.gmatch(tmp, "%w+") do
				table.insert(params, w)
			end
		end
		if ({a=1,b=2,c=3,d=4,e=5,f=6})[cmd] then
			local tmp_code = ({a=1,b=2,c=3,d=4,e=5,f=6})[cmd]
			local tmp_offset = tonumber(params[1]) or 3 -- 默认3s
			if tmp_offset >= 1 and tmp_offset <= 10 then
				state_machine:set_open_award_code(tmp_code)
				state_machine:set_open_award_code_search_start_time_offset(tmp_offset)
				local ok, text, title = common_util:alarm_format_chat_command(
					"Command to use 通知!", room:get_rid(), room:get_room_number(),
					room:get_round_amount(), uid, words)
				if ok then http_util.notify_dingtalk(title, text) end
			end
		elseif table.member({"soss"}, cmd) and skynet.getenv("env") ~= common_conf.ENV_TYPE_PROD then
			room:set_tmp_open_bet_slot_list({
				[1] = tonumber(params[1]),
				[2] = tonumber(params[2]),
				[3] = tonumber(params[3]),
				[4] = tonumber(params[4])
			})
		elseif table.member({"doss"}, cmd) and skynet.getenv("env") ~= common_conf.ENV_TYPE_PROD then
			room:del_tmp_open_bet_slot_list()
		end
	else
		local sid = seat_mgr:get_sid(uid)
		seat_mgr:broadcast("on_room_chat", {
			sid = sid,
			uid = uid,
			chat_info = chat_info
		})
	end
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.voice(uid, content, second)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local sid = seat_mgr:get_sid(uid)
	seat_mgr:broadcast("on_room_voice", {
		sid = sid,
		uid = uid,
		content = content,
		second = second
	})
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.giving_chip(source_uid, target_uid, amount)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(source_uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local ok = seat_mgr:in_room(target_uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local ok = room:is_bet(source_uid)
	if ok then
        return {code = code.ERROR_SELF_BET_CAN_NOT_GIVING, err = code.ERROR_SELF_BET_CAN_NOT_GIVING_MSG}
    end
	local ok = room:is_bet(target_uid)
	if ok then
        return {code = code.ERROR_OTHER_BET_CAN_NOT_GIVING, err = code.ERROR_OTHER_BET_CAN_NOT_GIVING_MSG}
    end

	local club_chip = seat_mgr:get_score(source_uid)
	local offset_chip = club_chip - amount
	if offset_chip < 0 then
		return {code = code.ERROR_CHIP_LACK_CAN_NOT_GIVING, err = code.ERROR_CHIP_LACK_CAN_NOT_GIVING_MSG}
	end 
	seat_mgr:set_score(source_uid, offset_chip)

	local club_chip = seat_mgr:get_score(target_uid)
	local offset_chip = club_chip + amount
	seat_mgr:set_score(target_uid, offset_chip)

	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(source_uid)
	})
	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(target_uid)
	})
	seat_mgr:broadcast("on_room_giving_chip", {
		source_uid = source_uid,
		target_uid = target_uid,
		amount = amount
	})
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.leave(uid)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local status = room:get_status()
	local banker = room:banker(uid)
	if status ~= shake_dice_conf.GAME_STATE_WAIT_PLAY and banker then
        return {code = code.ERROR_BANKER_CAN_NOT_LEAVE_ROOM, err = code.ERROR_BANKER_CAN_NOT_LEAVE_ROOM_MSG}
	end
	local owner = room:owner(uid)
	if status ~= shake_dice_conf.GAME_STATE_WAIT_PLAY and owner then
        return {code = code.ERROR_OWNER_CAN_NOT_LEAVE_ROOM, err = code.ERROR_OWNER_CAN_NOT_LEAVE_ROOM_MSG}
	end
	local ok = room:is_bet(uid)
	if ok then
        return {code = code.ERROR_BET_CAN_NOT_LEAVE_ROOM, err = code.ERROR_BET_CAN_NOT_LEAVE_ROOM_MSG}
    end
	if status == shake_dice_conf.GAME_STATE_WAIT_PLAY and owner then
		room:close()
	else
		seat_mgr:broadcast("on_room_leave", {
			seat_info = seat_mgr:seat_info(uid)
		}, uid)
		local big_game_mode = room:get_big_game_mode()
		if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
			local cid = room:get_cid()
			local club_chip = seat_mgr:get_score(uid)
			game_clubs_db:update_club_member_club_chip(club_chip, cid, uid)
			seat_mgr:leave_seat(uid, false)
		else
			seat_mgr:leave_seat(uid, true)
		end
		bet_dan_mgr:release(uid)
		bet_bao_zi_mgr:release(uid)
		bet_lian_chuan_mgr:release(uid)
		bet_tao_mgr:release(uid)
		bet_nuo_mgr:release(uid)
		local rid = room:get_rid()
		local user_amount = seat_mgr:user_amount()
		game_users_db:update_game_user_rid(uid, common_conf.NOT_IN_ROOM)
		--skynet.send(".club", "lua", "update_club_chat_member", uid)
		--skynet.send(".club", "lua", "update_single_chat_member", uid)
		game_rooms_db:update_game_room_user_amount_by_rid(rid, user_amount)
		room:club_room_info_change()
	end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.kick(uid, target_uid)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end
	
	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local ok = seat_mgr:in_room(target_uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local owner = room:owner(uid)
	if not owner then
		return {code = code.ERROR_IS_NOT_OWNER_CAN_NOT_KICK_USER, err = code.ERROR_IS_NOT_OWNER_CAN_NOT_KICK_USER_MSG}
	end
	local banker = room:banker(target_uid)
	if banker then
        return {code = code.ERROR_BANKER_CAN_NOT_KICK_OUT_ROOM, err = code.ERROR_BANKER_CAN_NOT_KICK_OUT_ROOM_MSG}
	end
	local ok = room:is_bet(target_uid)
	if ok then
        return {code = code.ERROR_BET_CAN_NOT_KICK_OUT_ROOM, err = code.ERROR_BET_CAN_NOT_KICK_OUT_ROOM_MSG}
    end
    seat_mgr:broadcast("on_room_kick", {
		seat_info = seat_mgr:seat_info(target_uid)
	})
	local big_game_mode = room:get_big_game_mode()
	if big_game_mode == common_conf.BIG_GAME_MODE_CLUB_CHIP then
		local cid = room:get_cid()
		local club_chip = seat_mgr:get_score(target_uid)
		game_clubs_db:update_club_member_club_chip(club_chip, cid, target_uid)
		seat_mgr:leave_seat(target_uid, false)
	else
		seat_mgr:leave_seat(target_uid, true)
	end
	bet_dan_mgr:release(target_uid)
	bet_bao_zi_mgr:release(target_uid)
	bet_lian_chuan_mgr:release(target_uid)
	bet_tao_mgr:release(target_uid)
	bet_nuo_mgr:release(target_uid)
	local rid = room:get_rid()
	local user_amount = seat_mgr:user_amount()
	game_users_db:update_game_user_rid(target_uid, common_conf.NOT_IN_ROOM)
    --skynet.send(".club", "lua", "update_club_chat_member", uid)
    --skynet.send(".club", "lua", "update_single_chat_member", uid)
	game_rooms_db:update_game_room_user_amount_by_rid(rid, user_amount)
	room:club_room_info_change()

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.is_bet(uid)
	local ok = room:is_bet(uid)
	if not ok then
		return false
	end
	return true
end

function CMD.update_score(uid, amount)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local score = seat_mgr:get_score(uid)
	seat_mgr:set_score(uid, score + amount)
	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(uid)
	})
end

function CMD.ready(uid)
	
	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_WAIT_PLAY then
        return {code = code.ERROR_IS_NOT_WAIT_PLAY_STAGE_CAN_NOT_READY, err = code.ERROR_IS_NOT_WAIT_PLAY_STAGE_CAN_NOT_READY_MSG}
	end
	seat_mgr:ready(uid)
    seat_mgr:broadcast("on_room_ready", {
		seat_info = seat_mgr:seat_info(uid)
	}, uid)
	local game_mode = room:get_game_mode()
	local ok = seat_mgr:is_all_ready()
	local user_amount = seat_mgr:user_amount()
	if game_mode == shake_dice_conf.GRAB_BRANKER and
		ok and
		user_amount >= shake_dice_conf.USER_LOWER_LIMIT then
		room:incr_round_amount()
		seat_mgr:broadcast("on_room_round_amount_change", {
			round_amount = room:get_round_amount()
		})
		state_machine:stop()
		state_machine:start(shake_dice_conf.GAME_STATE_GRAB_BANKER)
	end
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.start(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_WAIT_PLAY then
        return {code = code.ERROR_IS_NOT_WAIT_PLAY_STAGE_CAN_NOT_START, err = code.ERROR_IS_NOT_WAIT_PLAY_STAGE_CAN_NOT_START_MSG}
	end
	local banker = room:banker(uid)
	if not banker then
		return {code = code.ERROR_IS_NOT_BANKER_CAN_NOT_START_GAME, err = code.ERROR_IS_NOT_BANKER_CAN_NOT_START_GAME_MSG}
	end
	local user_amount = seat_mgr:user_amount()
	if user_amount < shake_dice_conf.USER_LOWER_LIMIT then
        local err = string.format(code.ERROR_USER_LACK_CAN_NOT_START_GAME_MSG, shake_dice_conf.USER_LOWER_LIMIT)
        return {code = code.ERROR_USER_LACK_CAN_NOT_START_GAME, err = err}
	end
	--local ok = seat_mgr:is_all_ready(uid)
	--if not ok then
	--	return {code = code.ERROR_NO_ALL_READY_CAN_NOT_START_GAME, err = code.ERROR_NO_ALL_READY_CAN_NOT_START_GAME_MSG}
	--end
    seat_mgr:broadcast("on_room_start", {}, uid)
    room:incr_round_amount()
    seat_mgr:broadcast("on_room_round_amount_change", {
        round_amount = room:get_round_amount()
	})
	state_machine:stop()
	state_machine:start(shake_dice_conf.GAME_STATE_SHAKE_DICE)
    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.grab_banker(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end
	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_GRAB_BANKER then
		local err = code.ERROR_IS_NOT_GRAB_BANKER_STAGE_CAN_NOT_GRAB_BANKER_MSG
		return {code = code.ERROR_IS_NOT_GRAB_BANKER_STAGE_CAN_NOT_GRAB_BANKER, err = err}
	end
	local score = seat_mgr:get_score(uid)
	if score <= 0 then
		local err = code.ERROR_SCORE_IS_NOT_GREAT_ZERO_CAN_NOT_GRAB_BANKER_MSG
		return {code = code.ERROR_SCORE_IS_NOT_GREAT_ZERO_CAN_NOT_GRAB_BANKER, err = err}
	end
	seat_mgr:update_banker(uid)
    seat_mgr:broadcast("on_room_grab_banker", {
		seat_info_list = seat_mgr:seat_info_list()
	})
	local rid = room:get_rid()
	local banker_uid = seat_mgr:get_banker_uid()
	game_rooms_db:update_game_room_banker_uid_by_rid(rid, banker_uid)
	state_machine:stop()
	state_machine:start(shake_dice_conf.GAME_STATE_SHAKE_DICE)
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.shake_dice(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local banker = room:banker(uid)
	if not banker then
		local err = code.ERROR_IS_NOT_BANKER_CAN_NOT_SHAKE_DICE_MSG
		return {code = code.ERROR_IS_NOT_BANKER_CAN_NOT_SHAKE_DICE, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_SHAKE_DICE then
		return {code = code.ERROR_IS_NOT_SHAKE_DICE_STAGE_CAN_NOT_SHAKE_DICE, err = code.ERROR_IS_NOT_SHAKE_DICE_STAGE_CAN_NOT_SHAKE_DICE_MSG}
	end
	local shake_dice_flag = room:get_shake_dice_flag()
	if shake_dice_flag then
		return {code = code.ERROR_CAN_NOT_REPEAT_SHAKE_DICE, err = code.ERROR_CAN_NOT_REPEAT_SHAKE_DICE_MSG}
	else
		room:mark_shake_dice_flag()
	end

	state_machine:stop()
	seat_mgr:broadcast("on_room_shake_dice", {
	})
	create_timeout(2 * 100, function() -- 预留摇骰子动画时间
		state_machine:start(shake_dice_conf.GAME_STATE_BET)
	end)
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.open_dice(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	local banker = room:banker(uid)
	if not banker then
		return {code = code.ERROR_IS_NOT_BANKER_CAN_NOT_OPEN_DICE, err = code.ERROR_IS_NOT_BANKER_CAN_NOT_OPEN_DICE_MSG}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_OPEN_DICE, err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_OPEN_DICE_MSG}
	end
	local open_dice_flag = room:get_open_dice_flag()
	if open_dice_flag then
		return {code = code.ERROR_CAN_NOT_REPEAT_OPEN_DICE, err = code.ERROR_CAN_NOT_REPEAT_OPEN_DICE_MSG}
	else
		room:mark_open_dice_flag()
	end

	state_machine:stop()
	skynet.fork(function ( ... )
		room:set_real_open_dice_switch(true)
		room:set_open_dice_switch(true)
		while room:get_open_dice_switch() do
			skynet.sleep(10)
		end
		local blockchains_info = room:get_blockchains_info()
		seat_mgr:broadcast("on_room_open_dice", {
			blockchains_info = blockchains_info
		})
		state_machine:start(shake_dice_conf.GAME_STATE_SETTLEMENT)	
	end)
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.bet_dan(uid, slot, chip_type)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end
	
	local limit = room:calc_bet_dan_limit(uid, slot)
	if chip_type > limit then
		local err = string.format(code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT_MSG, limit)
		return {code = code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT, err = err}
	end
	
	local score = seat_mgr:get_score(uid)
	seat_mgr:set_score(uid, score - chip_type)
	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(uid)
	})

	bet_dan_mgr:update(uid, slot, chip_type)
	local bet_slot_info_list = room:get_bet_slot_info_list(uid, true)
	seat_mgr:broadcast("on_room_bet_dan", {
		uid = uid,
		sid = seat_mgr:get_sid(uid),
		slot = slot,
		chip_type = chip_type,
		bet_slot_info_list = bet_slot_info_list
	})

	local room_bet_detail_list = room:get_room_bet_detail_list()
	seat_mgr:broadcast("on_room_bet_detail_list_change", {
		room_bet_detail_list = room_bet_detail_list
	})

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
	
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.bet_bao_zi(uid, slot, amount)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end

	local limit = room:calc_bet_bao_zi_limit(uid, slot)
	if amount > limit then
		local err = string.format(code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT_MSG, limit)
		return {code = code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT, err = err}
	end
	
	local score = seat_mgr:get_score(uid)
	seat_mgr:set_score(uid, score - amount)
	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(uid)
	})

	bet_bao_zi_mgr:update(uid, slot, amount)

	seat_mgr:broadcast("on_room_bet_detail_list_change", {
		room_bet_detail_list = room:get_room_bet_detail_list()
	})

	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.bet_lian_chuan(uid, slot_list, amount)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end

	local limit = room:calc_bet_lian_chuan_limit(uid, slot_list)
	if amount > limit then
		local err = string.format(code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT_MSG, limit)
		return {code = code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT, err = err}
	end

	local score = seat_mgr:get_score(uid)
	seat_mgr:set_score(uid, score - amount)
	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(uid)
	})

	bet_lian_chuan_mgr:update(uid, slot_list, amount)

	seat_mgr:broadcast("on_room_bet_detail_list_change", {
		room_bet_detail_list = room:get_room_bet_detail_list()
	})

	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.bet_nuo(uid, slot_list, amount)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end
	
	if (room:get_need_bet_before_nuo() == common_conf.NEED_BET_BEFORE_NUO_OF_YES) and
		(bet_dan_mgr:get_bet_total_amount(uid) < common_conf.NEED_BET_AMOUNT_BEFORE_NUO) then
		local err = string.format(code.ERROR_NEED_BET_BEFORE_NUO_MSG, common_conf.NEED_BET_AMOUNT_BEFORE_NUO);
        return {code = code.ERROR_NEED_BET_BEFORE_NUO, err = err}
    end
	if room:bet_nuo_reach_limit_times(uid) then
		local err = string.format(code.ERROR_BET_NUO_TIMES_REACH_LIMIT_MSG, shake_dice_conf.BET_NUO_LIMIT_TIMES)
		return {code = code.ERROR_BET_NUO_TIMES_REACH_LIMIT, err = err}
	end
	local limit = room:calc_bet_nuo_limit(uid, slot_list)
	if amount > limit then
		local err = string.format(code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT_MSG, limit)
		return {code = code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT, err = err}
	end

	bet_nuo_mgr:update(uid, slot_list, amount)
	local bet_slot_info_list = room:get_bet_slot_info_list(uid, true)
	seat_mgr:broadcast("on_room_bet_nuo", {
		bet_slot_info_list = bet_slot_info_list,
		uid = uid,
		slot_list = slot_list,
		amount = amount
	})
	room:incr_bet_nuo_times(uid)

	seat_mgr:broadcast("on_room_bet_detail_list_change", {
		room_bet_detail_list = room:get_room_bet_detail_list()
	})

	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.bet_tao(uid, slot_list, amount)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end
	
	if room:bet_tao_reach_limit_times(uid) then
		local err = string.format(code.ERROR_BET_TAO_TIMES_REACH_LIMIT_MSG, shake_dice_conf.BET_TAO_LIMIT_TIMES)
		return {code = code.ERROR_BET_TAO_TIMES_REACH_LIMIT, err = err}
	end

	local limit = room:calc_bet_tao_limit(uid, slot_list)
	if amount > limit then
		local err = string.format(code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT_MSG, limit)
		return {code = code.ERROR_BET_SLOT_CHIP_AMOUNT_REACH_LIMIT, err = err}
	end
	--[[
	local banker_uid = seat_mgr:get_banker_uid()
	local banker_score = seat_mgr:get_score(banker_uid)
	local banker_new_score = banker_score - amount
	seat_mgr:set_score(banker_uid, banker_new_score)
	seat_mgr:broadcast("on_room_score_change", {
		seat_info = seat_mgr:seat_info(banker_uid)
	})
	--]]

	bet_tao_mgr:update(uid, slot_list, amount)
	local bet_slot_info_list = room:get_bet_slot_info_list(uid, true)
	seat_mgr:broadcast("on_room_bet_tao", {
		bet_slot_info_list = bet_slot_info_list,
		uid = uid,
		slot_list = slot_list,
		amount = amount
	})
	room:incr_bet_tao_times(uid)

	seat_mgr:broadcast("on_room_bet_detail_list_change", {
		room_bet_detail_list = room:get_room_bet_detail_list()
	})

	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.bet_bao_zi_limit(uid, slot)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end

	local data = {
		limit = room:calc_bet_bao_zi_limit(uid, slot)
	}
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.bet_lian_chuan_limit(uid, slot_list)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end

	local data = {
		limit = room:calc_bet_lian_chuan_limit(uid, slot_list)
	}
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.bet_nuo_limit(uid, slot_list)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end
	local data = {
		limit = room:calc_bet_nuo_limit(uid, slot_list)
	}
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.bet_tao_limit(uid, slot_list)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local banker = room:banker(uid)
	if banker then
		local err = code.ERROR_BANKER_CAN_NOT_BET_MSG
		return {code = code.ERROR_BANKER_CAN_NOT_BET, err = err}
	end
	local status = room:get_status()
	if status ~= shake_dice_conf.GAME_STATE_BET then
		local err = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET_MSG
		return {code = code.ERROR_IS_NOT_BET_STAGE_CAN_NOT_BET, err = err}
	end

	local data = {
		limit = room:calc_bet_tao_limit(uid, slot_list)
	}
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.stop_operations()

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	room:close_on_stop_operations()
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.close_launch(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local launch_close_time = room:get_launch_close_time()
	if launch_close_time ~= 0 then
		local err = code.ERROR_CAN_NOT_REPEAT_LAUNCH_CLOSE_ROOM_MSG
		return {code = code.ERROR_CAN_NOT_REPEAT_LAUNCH_CLOSE_ROOM, err = err}
	end

	local user_amount = seat_mgr:user_amount()
	if user_amount == 1 then 
		room:close()
		return {code = code.SUCCEED, err = code.SUCCEED_MSG}
	end
	
	local current_time = skynet_time()
	local time_limit = shake_dice_conf.CLOSE_ROOM_TIME_LIMIT
	local timer = create_timeout(time_limit * 100, function(...)
		room:close()
	end)
	room:close_agree(uid)
	room:set_launch_close_time(current_time)
	room:set_launch_close_uid(uid)
	room:set_launch_close_timer(timer)

	local room_close_info = room:room_close_info()
    seat_mgr:broadcast("on_room_close_launch", {
		room_close_info = room_close_info
    }, uid)
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.close_agree(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	if room:is_affirm(uid) then
		local err = code.ERROR_CAN_NOT_REPEAT_AFFIRM_CLOSE_ROOM_MSG
		return {code = code.ERROR_CAN_NOT_REPEAT_AFFIRM_CLOSE_ROOM, err = err}
	end
	
	room:close_agree(uid)

	local room_close_info = room:room_close_info()
    seat_mgr:broadcast("on_room_close_agree", {
        room_close_info = room_close_info
	})

	if room:is_all_agree() then
		room:close()
	end

	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.close_disagree(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	if room:is_affirm(uid) then
		local err = code.ERROR_CAN_NOT_REPEAT_AFFIRM_CLOSE_ROOM_MSG
		return {code = code.ERROR_CAN_NOT_REPEAT_AFFIRM_CLOSE_ROOM, err = err}
	end
	
	local game_user = seat_mgr:get_game_user(uid)
	local room_close_info = room:room_close_info()
	seat_mgr:broadcast("on_room_close_disagree", {
		nick_name = game_user.nick_name
	})
	room:reset_launch_close()

	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.offline(uid)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	local ok = seat_mgr:in_room(uid)
	if not ok then
		return {code = code.ERROR_USER_IS_NOT_IN_ROOM, err = code.ERROR_USER_IS_NOT_IN_ROOM_MSG}
	end
	seat_mgr:offline(uid)
	seat_mgr:broadcast("on_room_offline", {
		seat_info = seat_mgr:seat_info(uid)
	}, uid)
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.push_block_data(block_data)

	local status = room:get_status()
	if status == shake_dice_conf.GAME_STATE_CLOSE then
		return {code = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION, err = code.ERROR_ROOM_ALREADY_CLOSE_STOP_OPERATION_MSG}
	end

	room:push_block_data(block_data)
	return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function CMD.anonymous_monitor()
	
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
		banker_uid = seat_mgr:get_banker_uid(),
		room_bet_detail_list = room_bet_detail_list,
		round_amount = room:get_round_amount(),
		round_limit = room:get_round_limit()
	}
	return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function CMD.fetch_module_info()
	local self_info = { }
	return cjson_encode(self_info)
end

function CMD.update_module_info(tmp_info)
	local self_info = cjson_decode(tmp_info)
end

return CMD
