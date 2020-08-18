local skynet = require "skynet"
local code = require "server.config.code"
local game_db = require "server.common.game_db"
local game_users_db = require "server.common.game_users_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_lualib_misc_helper")

local CLUB_RANK_LIST = {}
local CLUB_RANK_TICK = 0

local CMD = {}

function CMD.get_club_rank_list()
    return CLUB_RANK_LIST, CLUB_RANK_TICK
end

function CMD.set_club_rank_list(club_rank_list, club_rank_tick)
    CLUB_RANK_LIST = club_rank_list
    CLUB_RANK_TICK = club_rank_tick
end

function CMD.patch_user_room_records()
    game_db:patch_user_room_records()
    return "success"
end

function CMD.fetch_module_info()
    local self_info = {
        club_rank_list = CLUB_RANK_LIST,
        club_rank_tick = CLUB_RANK_TICK,
    }
    return cjson_encode(self_info)
end

function CMD.update_module_info(tmp_info)
    local self_info = cjson_decode(tmp_info)

    CLUB_RANK_LIST = self_info.club_rank_list
    CLUB_RANK_TICK = self_info.club_rank_tick
end

return CMD
