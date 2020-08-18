local skynet = require "skynet"
local shake_dice_conf = require "server.config.shake_dice_conf"
local bet_dan_mgr = require "server.lualib.bet_dan_mgr"
local bet_bao_zi_mgr = require "server.lualib.bet_bao_zi_mgr"
local bet_lian_chuan_mgr = require "server.lualib.bet_lian_chuan_mgr"
local bet_tao_mgr = require "server.lualib.bet_tao_mgr"
local bet_nuo_mgr = require "server.lualib.bet_nuo_mgr"
local common_util = require "server.common.common_util"

function bet_dan()
    bet_dan_mgr:init()
    local uid = 12580
    bet_dan_mgr:alloc(uid)
    local slot = shake_dice_conf.BET_SLOT_LIST[1]
    local chip_type = shake_dice_conf.CHIP_TYPE_ONE
    bet_dan_mgr:update(uid, slot, chip_type)
    print(bet_dan_mgr:get_bet_slot_info_list(uid))
    bet_dan_mgr:reset(uid)
    bet_dan_mgr:release(uid)
end

function bet_bao_zi()
    bet_bao_zi_mgr:init()
    local uid = 12580
    bet_bao_zi_mgr:alloc(uid)
    local slot = shake_dice_conf.BET_SLOT_LIST[1]
    local amount = 1000
    bet_bao_zi_mgr:update(uid, slot, amount)
    print(bet_bao_zi_mgr:totable())
    bet_bao_zi_mgr:reset(uid)
    bet_bao_zi_mgr:release(uid)
end

function bet_nuo()
    bet_nuo_mgr:init()
    local uid = 12580
    local results = common_util:fetch_combined(shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST)
    bet_nuo_mgr:alloc(uid, results)
    local slot_list = {[1] = 12, [2] = 1}
    local amount = 800
    bet_nuo_mgr:update(uid, slot_list, amount)
    local res = bet_nuo_mgr:round_settlement(uid, {[1] = 1, [2] = 1, [3] = 8, [4] = 12}, 2)
    print(res)
    bet_nuo_mgr:reset(uid)
    bet_nuo_mgr:release(uid)
end

function bet_tao()
    bet_tao_mgr:init()
    local uid = 12580
    local results = common_util:fetch_combined(shake_dice_conf.SHENG_XIAO_BET_SLOT_LIST)
    bet_tao_mgr:alloc(uid, results)
    local slot_list = {[1] = 4, [2] = 10}
    local amount = 800
    bet_tao_mgr:update(uid, slot_list, amount)
    local res = bet_tao_mgr:round_settlement(uid, {[1] = 4, [2] = 6, [3] = 9, [4] = 10}, 2)
    print(res)
    bet_tao_mgr:reset(uid)
    bet_tao_mgr:release(uid)
end

skynet.start(function()
    bet_nuo()
    bet_tao()
    local results = common_util:fetch_combined({1, 2, 3, 4, 5, 6})
    print(#results)
    skynet.sleep(100 * 3)
    skynet.exit()
end)


--[[ -- 十二生肖挪讨
o [1] = 4, [2] = 6, [3] = 9, [4] = 10
s [1] = 4, [2] = 10

(s[2] == o[1] and s[2] == o[2]) or (s[2] == o[3] and s[2] == o[4]) 自己赢 双
(s[1] == o[1] and s[1] == o[2]) or (s[1] == o[3] and s[1] == o[4]) 自己输 双

(s[2] == o[1] and s[1] ~= o[2]) 自己赢 单
(s[2] == o[2] and s[1] ~= o[1]) 自己赢 单
(s[2] == o[3] and s[1] ~= o[4]) 自己赢 单
(s[2] == o[4] and s[1] ~= o[3]) 自己赢 单

(s[1] == o[1] and s[2] ~= o[2]) 自己输 单
(s[1] == o[2] and s[2] ~= o[1]) 自己输 单
(s[1] == o[3] and s[2] ~= o[4]) 自己输 单
(s[1] == o[4] and s[2] ~= o[3]) 自己输 单
--]]

--[[ -- 铜钱鸡挪讨
o [1] = 4, [2] = 10, [3] = 9
s [1] = 4, [2] = 10

(s[2] == o[1] and s[2] == o[2] and s[2] == o[3]) 自己赢 三
(s[1] == o[1] and s[1] == o[2] and s[1] == o[3]) 自己输 三

(s[2] == o[1] and s[2] == o[2]) 自己赢 二
(s[2] == o[1] and s[2] == o[3]) 自己赢 二
(s[2] == o[2] and s[2] == o[3]) 自己赢 二

(s[1] == o[1] and s[1] == o[2]) 自己输 二
(s[1] == o[1] and s[1] == o[3]) 自己输 二
(s[1] == o[2] and s[1] == o[3]) 自己输 二

(s[2] == o[1]) 自己赢 一
(s[2] == o[2]) 自己赢 一
(s[2] == o[3]) 自己赢 一

(s[1] == o[1]) 自己输 一
(s[1] == o[2]) 自己输 一
(s[1] == o[3]) 自己输 一
--]]
