local BET_SLOT_1 = 1
local BET_SLOT_2 = 2
local BET_SLOT_3 = 3
local BET_SLOT_4 = 4
local BET_SLOT_5 = 5
local BET_SLOT_6 = 6

local CHIP_TYPE_ONE = 20
local CHIP_TYPE_TWO = 50
local CHIP_TYPE_THREE = 250
local CHIP_TYPE_FOUR = 500
local CHIP_TYPE_FIVE = 1000

local FIXED_BRANKER = 1
local GRAB_BRANKER = 2

local BET_TYPE_DAN = 1
local BET_TYPE_BAO_ZI = 2
local BET_TYPE_LIAN_CHUAN = 3
local BET_TYPE_NUO = 4
local BET_TYPE_TAO = 5

local GAME_STATE_WAIT_PLAY = 1
local GAME_STATE_GRAB_BANKER = 2
local GAME_STATE_SHAKE_DICE = 3
local GAME_STATE_BET = 4
local GAME_STATE_SETTLEMENT = 5
local GAME_STATE_WAIT_NEXT_ROUND = 6

local GAME_STATE_CLOSE = 7

local TIME_LIMIT_WAIT_PLAY = 3600
local TIME_LIMIT_GRAB_BRANKER = 5
local TIME_LIMIT_SHAKE_DICE = 3
local TIME_LIMIT_BET = 47
local TIME_LIMIT_SETTLEMENT = 0
local TIME_LIMIT_WAIT_NEXT_ROUND = 5

root = {}

root.GAME_STATE_WAIT_PLAY = GAME_STATE_WAIT_PLAY
root.GAME_STATE_GRAB_BANKER = GAME_STATE_GRAB_BANKER
root.GAME_STATE_SHAKE_DICE = GAME_STATE_SHAKE_DICE
root.GAME_STATE_BET = GAME_STATE_BET
root.GAME_STATE_SETTLEMENT = GAME_STATE_SETTLEMENT
root.GAME_STATE_WAIT_NEXT_ROUND = GAME_STATE_WAIT_NEXT_ROUND

root.GAME_STATE_CLOSE = GAME_STATE_CLOSE

root.TIME_LIMIT_WAIT_PLAY = TIME_LIMIT_WAIT_PLAY
root.TIME_LIMIT_GRAB_BRANKER = TIME_LIMIT_GRAB_BRANKER
root.TIME_LIMIT_SHAKE_DICE = TIME_LIMIT_SHAKE_DICE
root.TIME_LIMIT_BET = TIME_LIMIT_BET
root.TIME_LIMIT_SETTLEMENT = TIME_LIMIT_SETTLEMENT
root.TIME_LIMIT_WAIT_NEXT_ROUND = TIME_LIMIT_WAIT_NEXT_ROUND

root.GAME_STATE_TIME_LIMIT_MAP = {
    [GAME_STATE_WAIT_PLAY] = TIME_LIMIT_WAIT_PLAY,
    [GAME_STATE_GRAB_BANKER] = TIME_LIMIT_GRAB_BRANKER,
    [GAME_STATE_SHAKE_DICE] = TIME_LIMIT_SHAKE_DICE,
    [GAME_STATE_BET] = TIME_LIMIT_BET,
    [GAME_STATE_SETTLEMENT] = TIME_LIMIT_SETTLEMENT,
    [GAME_STATE_WAIT_NEXT_ROUND] = TIME_LIMIT_WAIT_NEXT_ROUND
}

root.CHIP_TYPE_ONE = CHIP_TYPE_ONE
root.CHIP_TYPE_TWO = CHIP_TYPE_TWO
root.CHIP_TYPE_THREE = CHIP_TYPE_THREE
root.CHIP_TYPE_FOUR = CHIP_TYPE_FOUR
root.CHIP_TYPE_FIVE = CHIP_TYPE_FIVE

root.DICE_AMOUNT = 2

root.USER_LOWER_LIMIT = 1

-- 创建房间配置
root.ROUND_LIMIT_LIST = {
    { value = 5, name = "5局" },
    { value = 10, name = "10局" },
    { value = 15, name = "15局" }
}
root.ROUND_LIMIT_LIST_CLUB_CHIP = {
    { value = 5, name = "5局" },
    { value = 10, name = "10局" },
    { value = 15, name = "15局" },
    { value = 60, name = "60局" }
}
root.USER_LIMIT_LIST = {
    { value = 10, name = "10人" },
    --{ value = 15, name = "15人" },
    { value = 20, name = "20人" }
}
root.GAME_MODE_LIST = {
    { value = FIXED_BRANKER, name = "固定庄" },
    { value = GRAB_BRANKER, name = "抢庄" }
}
root.GRAB_BRANKER = GRAB_BRANKER
root.FIXED_BRANKER = FIXED_BRANKER
root.BET_SLOT_LIMIT_LIST = {
    { value = 1000, name = "1000封" },
    { value = 2000, name = "2000封" },
    { value = 3000, name = "3000封" },
    { value = 5000, name = "5000封" },
    { value = 6000, name = "6000封" },
    { value = 7000, name = "7000封" },
    { value = 8000, name = "8000封" },
    { value = 9000, name = "9000封" },
    { value = 10000, name = "10000封" },
    { value = 15000, name = "15000封" },
    { value = 20000, name = "20000封" },
    { value = 50000, name = "50000封" }
}
root.CARRY_SCORE_LIST = {
    { value = 10000, name = "10000分" },
    { value = 13000, name = "13000分" },
    { value = 20000, name = "20000分" },
    { value = 30000, name = "30000分" },
    { value = 40000, name = "40000分" },
    { value = 50000, name = "50000分" },
    { value = 60000, name = "60000分" },
    { value = 70000, name = "70000分" },
    { value = 80000, name = "80000分" },
    { value = 90000, name = "90000分" },
    { value = 100000, name = "100000分" },
    { value = 0, name = "无限" }
}

root.CHIP_TYPE_LIST = {
    CHIP_TYPE_ONE,
    CHIP_TYPE_TWO,
    CHIP_TYPE_THREE,
    CHIP_TYPE_FOUR,
    CHIP_TYPE_FIVE
}

root.BET_TYPE_DAN = BET_TYPE_DAN
root.BET_TYPE_BAO_ZI = BET_TYPE_BAO_ZI
root.BET_TYPE_LIAN_CHUAN = BET_TYPE_LIAN_CHUAN
root.BET_TYPE_NUO = BET_TYPE_NUO
root.BET_TYPE_TAO = BET_TYPE_TAO

-- 押单,豹子类型
root.BET_SLOT_LIST = {
    BET_SLOT_1,
    BET_SLOT_2,
    BET_SLOT_3,
    BET_SLOT_4,
    BET_SLOT_5,
    BET_SLOT_6
}          

-- 连串下注限制 = 单位置下注限制 * 20 / 100
-- 豹子下注限制 = 单位置下注限制 * 10 / 100
-- 挪下注限制
    -- 如果 [(自己的分数 * 20 / 100) >= (挪源位置下注总数 * 80 / 100)] 则 [挪上限 = (挪源位置下注总数 * 80 / 100)]
    -- 如果 [(自己的分数 * 20 / 100) < (挪源位置下注总数 * 80 / 100)] 则 [挪上限 = (自己的分数 * 20 / 100)]
    -- 如果 [自己的分数 <= 0] 则 [挪上限 = 0]

    -- 如果 无限模式 则 [挪上限 = (挪源位置下注总数 * 80 / 100)]
-- 讨下注限制
    -- 如果 [(自己的分数 * 20 / 100) >= 单个位置的上限] 则 [讨下注上限 = (单个位置的上限 * 10 / 100)]
    -- 如果 [(自己的分数 * 20 / 100) < 单个位置的上限] 则 [讨下注上限 = (自己的分数 * 20 / 100)]
    --      ((自己的分数 * 20 / 100) >= (单个位置的上限 * 10 / 100) 则 [讨下注上限 = (单个位置的上限 * 10 / 100)])
    -- 如果 [自己的分数 <= 0] 则 [讨上限 = 0]

    -- 如果 无限模式 则 [讨下注上限 = (单个位置的上限 * 10 / 100)]

root.BET_NUO_LIMIT_TIMES = 3
root.BET_TAO_LIMIT_TIMES = 1

-- 结算相关配置
root.WIN_MULTIPLE_DAN_OPEN_TWO = 2      -- 押单模式,开1个赢2倍
root.WIN_MULTIPLE_DAN_OPEN_FOUR = 4     -- 押单模式,开2个赢4倍
root.WIN_MULTIPLE_LIAN_CHUAN_12 = 12    -- 连串模式(选两个位置开中两个),赢12倍
root.WIN_MULTIPLE_BAO_ZI_25 = 25        -- 豹子模式(选一个位置开中两个),赢25倍

root.WIN_MULTIPLE_NUO_TWO = 2
root.WIN_MULTIPLE_NUO_FOUR = 4
-- 挪开一个骰子
-- 赢的钱 = 挪的钱(需要实时扣源位置的钱) + (挪的钱 * 2)[来自庄家]
-- 输的钱 = 挪的钱(需要实时扣源位置的钱) + (挪的钱 * 2)[来自自己]
-- 挪开两个骰子
-- 赢的钱 = 挪的钱(需要实时扣源位置的钱) + (挪的钱 * 4)[来自庄家]
-- 输的钱 = 挪的钱(需要实时扣源位置的钱) + (挪的钱 * 4)[来自自己]

root.WIN_MULTIPLE_TAO_TWO = 2
root.WIN_MULTIPLE_TAO_FOUR = 4
-- 讨开一个骰子
-- 赢的钱 = 讨的钱(讨的时候需要实时扣庄家的钱) + (讨的钱 * 2)[来自庄家]
-- 输的钱 = 讨的钱(讨的时候需要实时扣庄家的钱) + (讨的钱 * 2)[来自自己]
-- 讨开两个骰子
-- 赢的钱 = 讨的钱(讨的时候需要实时扣庄家的钱) + (讨的钱 * 4)[来自庄家]
-- 输的钱 = 讨的钱(讨的时候需要实时扣庄家的钱) + (讨的钱 * 4)[来自自己]

-- 讨的时候从庄家那里扣除,结算的时候也需要还给庄家

root.CLOSE_ROOM_TIME_LIMIT = 60
root.CLOSE_AGREE = 1
root.CLOSE_DISAGREE = 0

root.CHAT_TYPE_FACE = 1
root.CHAT_TYPE_VOICE = 2
root.CHAT_TYPE_WORDS = 3

root.ROOM_RECORD_AMOUNT_LIMIT = 1000
root.ROOM_RECORD_TIME_LIMIT = 604800

-- 为十二生肖游戏附加的配置
local BET_SLOT_7 = 7
local BET_SLOT_8 = 8
local BET_SLOT_9 = 9
local BET_SLOT_10 = 10
local BET_SLOT_11 = 11
local BET_SLOT_12 = 12

-- 押单,豹子类型
root.SHENG_XIAO_BET_SLOT_LIST = {
    BET_SLOT_1,
    BET_SLOT_2,
    BET_SLOT_3,
    BET_SLOT_4,
    BET_SLOT_5,
    BET_SLOT_6,
    BET_SLOT_7,
    BET_SLOT_8,
    BET_SLOT_9,
    BET_SLOT_10,
    BET_SLOT_11,
    BET_SLOT_12
}

-- 十二生肖结算相关配置
root.WIN_MULTIPLE_DAN_OPEN_THREE = 3      -- 押单,开2个赢3倍
root.WIN_MULTIPLE_NUO_THREE = 3           -- 挪,开2个赢3个
root.WIN_MULTIPLE_TAO_THREE = 3           -- 讨,开2个赢3个

-- 铜钱鸡结算相关配置
root.WIN_MULTIPLE_DAN_OPEN_ONE = 1        -- 押单,开一个赢1倍
root.WIN_MULTIPLE_NUO_ONE = 1             -- 挪,开1个赢1倍
root.WIN_MULTIPLE_TAO_ONE = 1             -- 讨,开1个赢1倍
root.WIN_MULTIPLE_LIAN_CHUAN_5 = 4        -- 连串,每一方开1个赢4倍
root.WIN_MULTIPLE_LIAN_CHUAN_8 = 7        -- 连串,一方开1个,另一方开2个赢7倍
root.WIN_MULTIPLE_BAO_ZI_150 = 30         -- 豹子模式(选一个位置开中三个),赢30倍

return root
