local RECHARGE_TYPE_GOLD_COIN = 1
local RECHARGE_TYPE_DIAMOND = 2
local RECHARGE_TYPE_ROOM_CARD = 3

local GAME_TYPE_YU_XIA_XIE = 1
local GAME_TYPE_TONG_QIAN_JI = 2
local GAME_TYPE_SHI_ER_SHENG_XIAO = 3

local WECHAT_APP_PLATFORM_MOBILE = "mobile"
local WECHAT_APP_PLATFORM_WEBSITE = "website"
local WECHAT_APP_PLATFORM_PUBLIC = "public"

local BIG_GAME_MODE_NORMAL_SCORE = 1
local BIG_GAME_MODE_CLUB_SCORE = 2
local BIG_GAME_MODE_CLUB_CHIP = 3
local BIG_GAME_MODE_GOLD_FIELD = 4

local CLUB_CHAT_TYPE_TEXT = 1
local CLUB_CHAT_TYPE_RECORD = 2
local CLUB_CHAT_TYPE_PICTURE = 3
local CLUB_CHAT_TYPE_VOICE = 4
local CLUB_CHAT_TYPE_FACE = 5

local RED_DOT_ID_ON_CLUB_APPLY = 10001  -- 红点ID


local NEED_BET_BEFORE_NUO_OF_YES = 1
local NEED_BET_BEFORE_NUO_OF_NO = 0

local root = {}

root.RECHARGE_TYPE_GOLD_COIN = RECHARGE_TYPE_GOLD_COIN
root.RECHARGE_TYPE_DIAMOND = RECHARGE_TYPE_DIAMOND
root.RECHARGE_TYPE_ROOM_CARD = RECHARGE_TYPE_ROOM_CARD

root.DEFAULT_DISCOUNT = 0
root.DEFAULT_INVITE_CODE = 0

root.INVITE_CODE_ROLE_PARTNER = 1
root.INVITE_CODE_ROLE_SUPER_AGENT = 2
root.INVITE_CODE_ROLE_NORMAL_AGENT = 3
root.INVITE_CODE_AGENT_REMARK = "NULL"

root.RECHARGE_SHOW = 1
root.RECHARGE_UNSHOW = 0
root.RECHARGE_SHOW_TYPE_MOBILE = 1
root.RECHARGE_SHOW_TYPE_PUBLIC = 2

root.RECHARGE_TYPE_LIST = {
    [1] = RECHARGE_TYPE_GOLD_COIN,      -- 金币
    [2] = RECHARGE_TYPE_DIAMOND,        -- 钻石
    [3] = RECHARGE_TYPE_ROOM_CARD,      -- 房卡
}

root.GAME_TYPE_YU_XIA_XIE = GAME_TYPE_YU_XIA_XIE
root.GAME_TYPE_TONG_QIAN_JI = GAME_TYPE_TONG_QIAN_JI
root.GAME_TYPE_SHI_ER_SHENG_XIAO = GAME_TYPE_SHI_ER_SHENG_XIAO

root.GAME_TYPE_LIST = {
    { value = GAME_TYPE_YU_XIA_XIE, name = "鱼虾蟹" },
    { value = GAME_TYPE_TONG_QIAN_JI, name = "铜钱鸡" },
    { value = GAME_TYPE_SHI_ER_SHENG_XIAO, name = "十二生肖" }
}

root.MUSIC_RANGE_MIN = 0
root.MUSIC_RANGE_MAX = 100

root.ROOM_NUM_MAX = 65535
root.ROOM_NUM_MIN = 1

root.CLUB_AMOUNT_LIMIT = 10
root.CLUB_MEMBER_AMOUNT = 300
root.INIT_CLUB_CHIP = 0
root.CLUB_MEMBER_STATUS_LEAVE = 0
root.CLUB_MEMBER_STATUS_NORMAL = 1
root.CLUB_MEMBER_STATUS_MANAGER = 2
root.CLUB_MEMBER_STATUS_OWNER = 3
root.CLUB_APPLY_STATUS_WAIT = 1
root.CLUB_APPLY_STATUS_AGREE = 2
root.CLUB_APPLY_STATUS_DISAGREE = 3

root.NOT_IN_ROOM = 0

root.AGENCY = "zhongyouhui123456"

root.WECHAT_APP_PLATFORM_MOBILE = WECHAT_APP_PLATFORM_MOBILE
root.WECHAT_APP_PLATFORM_WEBSITE = WECHAT_APP_PLATFORM_WEBSITE
root.WECHAT_APP_PLATFORM_PUBLIC = WECHAT_APP_PLATFORM_PUBLIC
root.WECHAT_APP_PLATFORM_LIST = {
    WECHAT_APP_PLATFORM_MOBILE,
    WECHAT_APP_PLATFORM_WEBSITE,
    WECHAT_APP_PLATFORM_PUBLIC
}
root.WECHAT_APP_CONFIG = {
    [WECHAT_APP_PLATFORM_MOBILE] = {
        appid = "wx279574daba0d2f60",
        secret = "277e33562830834fad564661fcc4a65d",
        host = "https://api.weixin.qq.com"
    },
    [WECHAT_APP_PLATFORM_WEBSITE] = {
        appid = "wx2d55776244ce3ebc",
        secret = "bbea7f228a677efdc64cc76820a3a8a3",
        host = "https://api.weixin.qq.com"
    },
    [WECHAT_APP_PLATFORM_PUBLIC] = {
        appid = "wxf0643065014b586f",
        secret = "4edd28ac22ecd111efa6ceb8e1c2d0a9",
        host = "https://api.weixin.qq.com"
    }
}

root.WECHAT_MCH_HOST = "https://api.mch.weixin.qq.com"
root.WECHAT_MCH_ID = 1548380281
root.WECHAT_MCH_TRADE_TYPE = "APP"
root.WECHAT_MCH_BODY = "众友会房卡购买"
root.WECHAT_MCH_SECRET = "Hyv3uEYucVzN0Yib0JkR8z2IgdIdamJD"
root.WECHAT_MCH_PACKAGE = "Sign=WXPay"

root.PAGE_AMOUNT_MIN = 1
root.PAGE_AMOUNT_MAX = 10

root.NOT_AGENCY = 0
root.IS_AGENCY = 1

root.DFUSE_API_KEY = "server_ee1a737f1443defb05cac1583ba42b9d"
root.DFUSE_AUTH_URL = "http://zyhdfuse.yehma.com:8250"
root.DFUSE_BLOCK_ID_URL = "http://zyhdfuse.yehma.com:8251"
root.EOSFLARE_BLOCK_ID_URL = "https://api-v1.eosflare.io"

root.CARRY_SCORE_INFINITE = 0

root.STOP_OPERATIONS_TIPS = "服务器维护中,请稍后登陆!"
root.GAME_OPERATIONS_STATUS_RUNNING = 1
root.GAME_OPERATIONS_STATUS_STOP = 0

root.RID_SEED = 100000
root.UID_SEED = 131212
root.CID_SEED = 1212

root.GAME_SERVER_HOST_DEV = "http://gametest.zyhco.com:8201"
root.GAME_SERVER_HOST_TEST = "http://gametest.zyhco.com:8201"
root.GAME_SERVER_HOST_PROD = "http://gameprod.zyhco.com:8201"
root.ENV_TYPE_DEV = "dev"
root.ENV_TYPE_TEST = "test"
root.ENV_TYPE_PROD = "prod"

root.DINGTALK_HOST = "https://oapi.dingtalk.com"
root.DINGTALK_PATH = {
    ["prod"] = "/robot/send?access_token=ff092af2e3422b1d76ba8f7c6bb3b36c2fae66900a636b093f34d8ac4bfdd95d",
    ["test"] = "/robot/send?access_token=532b72ed0374fd3e7146540f6c70f68bbe5275b70b7b45a1ba4534b2d521d5ab",
    ["dev"] = "/robot/send?access_token=532b72ed0374fd3e7146540f6c70f68bbe5275b70b7b45a1ba4534b2d521d5ab",
}


root.RED_DOT_ID_ON_CLUB_APPLY = RED_DOT_ID_ON_CLUB_APPLY
root.RED_DOT_LIST = {
    { value = RED_DOT_ID_ON_CLUB_APPLY, name = "我的申请" }
}

root.TIME_LIMIT_WAIT_BLOCK_DATA = 10
root.DEFAULT_ANNOUNCEMENT = "管理员很懒，没有留下任何介绍!"
root.DEFAULT_TOTAL_CLUB_CHIP = 0
root.ANNOUNCEMENT_LENGTH_LIMIT = 200
root.CLUB_NAME_LENGTH_LIMIT = 20

root.BIG_GAME_MODE_NORMAL_SCORE = BIG_GAME_MODE_NORMAL_SCORE
root.BIG_GAME_MODE_CLUB_SCORE = BIG_GAME_MODE_CLUB_SCORE
root.BIG_GAME_MODE_CLUB_CHIP = BIG_GAME_MODE_CLUB_CHIP
root.BIG_GAME_MODE_GOLD_FIELD = BIG_GAME_MODE_GOLD_FIELD
root.BIG_GAME_MODE_LIST = {
    { value = BIG_GAME_MODE_NORMAL_SCORE, name = "普通积分模式" },
    { value = BIG_GAME_MODE_CLUB_SCORE, name = "俱乐部积分模式" },
    { value = BIG_GAME_MODE_CLUB_CHIP, name = "俱乐部筹码模式"},
    { value = BIG_GAME_MODE_GOLD_FIELD, name = "金币场模式"},
}
root.BIG_GAME_MODE_CLUB_LIST = {
    { value = BIG_GAME_MODE_CLUB_SCORE, name = "俱乐部积分模式" },
    { value = BIG_GAME_MODE_CLUB_CHIP, name = "俱乐部筹码模式"},
}
root.EXPEND_ROOM_CARD_COND_MAP = {
    {round_limit = 5, user_limit = 10, room_card = 2},
    {round_limit = 5, user_limit = 20, room_card = 4},
    {round_limit = 10, user_limit = 10, room_card = 3},
    {round_limit = 10, user_limit = 20, room_card = 6},
    {round_limit = 15, user_limit = 10, room_card = 4},
    {round_limit = 15, user_limit = 20, room_card = 8}
}
root.EXPEND_ROOM_CARD_COND_MAP_CLUB_CHIP = {
    {round_limit = 5, user_limit = 10, room_card = 2},
    {round_limit = 5, user_limit = 20, room_card = 4},
    {round_limit = 10, user_limit = 10, room_card = 3},
    {round_limit = 10, user_limit = 20, room_card = 6},
    {round_limit = 15, user_limit = 10, room_card = 4},
    {round_limit = 15, user_limit = 20, room_card = 8},
    {round_limit = 60, user_limit = 10, room_card = 16},
    {round_limit = 60, user_limit = 20, room_card = 32},
}

root.ONLINE = 1
root.OFFLINE = 0

root.UNEXPENDED = 0
root.EXPENDED = 1
root.ROOM_UNCLOSE = 1
root.ROOM_CLOSE = 0

root.SYSTEM_SETTING_TYPE_SCROLL_INFO = 1
root.SYSTEM_SETTING_TYPE_AGENCY_INFO = 2

root.NEW_USER_DEFAULT_ROOM_CARD_AMOUNT = 10
root.AUTH_CODE_VALID_TIME = 600

root.SMS_SERVICE_HOST = "http://kalasms.yehma.com"
root.SMS_SIGN_NAME = "众友会"
root.SMS_TEMPLATE_CODE = "SMS_174988141"

root.APPLE_ITUNES_HOST_DEV = "https://sandbox.itunes.apple.com"
root.APPLE_ITUNES_HOST_TEST = "https://sandbox.itunes.apple.com"
root.APPLE_ITUNES_HOST_PROD = "https://buy.itunes.apple.com"

root.BOUND_PHONE_NUMBER_GIFT_ROOM_CARD = 20

root.CHAT_UNREMIND = 0
root.CHAT_REMIND = 1
root.CHAT_UNREAD = 1
root.CHAT_READ = 0
root.CHAT_TYPE_GROUP = 1
root.CHAT_TYPE_SINGLE = 2
root.CHAT_LIST_LIFE_CYCLE_TIME = 259200
root.CLUB_CHAT_AMOUNT_LIMIT = 100
root.CLUB_CHAT_TYPE_LIST = {
    CLUB_CHAT_TYPE_TEXT,
    CLUB_CHAT_TYPE_RECORD,
    CLUB_CHAT_TYPE_PICTURE,
    CLUB_CHAT_TYPE_VOICE,
    CLUB_CHAT_TYPE_FACE
}

root.CLUB_RANK_OFFSET_TICK = 1800
root.CLUB_RANK_AMOUNT = 10
root.CLUB_RANK_FAKE_AMOUNT = 5
root.CLUB_RANK_DAY_BASE = 0
root.CLUB_JOIN_RANK = 1
root.CLUB_NOT_JOIN_RANK = 0

root.NOTICE_TYPE_WORDS = 1
root.NOTICE_TYPE_IMAGE = 2
root.NOTICE_POPUP_OFF = 0
root.NOTICE_POPUP_ON = 1
root.NOTICE_STATUS_OFF = 0
root.NOTICE_STATUS_ON = 1
root.NOTICE_IMAGE_ADDRESS = "http://kala-binary.oss-cn-shenzhen.aliyuncs.com/"

root.RANK_REAL_CLUB_LIST = {
    --{ cid = 1475, club_name = "兄弟盟" },
}

root.RANK_FAKE_CLUB_LIST = {
    ["prod"] = {
        { cid = 1472, club_name = "兄弟盟" },
        { cid = 1471, club_name = "鱼虾大聚会" },
        { cid = 1470, club_name = "帝国海鲜宴" },
        { cid = 1469, club_name = "小刀会" },
        { cid = 1468, club_name = "聚贤庄" },
        { cid = 1467, club_name = "财神客栈" },
        { cid = 1466, club_name = "鱼虾社" },
        { cid = 1465, club_name = "义气堂" },
        { cid = 1464, club_name = "鱼虾蟹大乱斗" },
        { cid = 1463, club_name = "风云大排档" }
    },
    ["test"] = {
        { cid = 1253, club_name = "test" },
        { cid = 1252, club_name = "test" },
        { cid = 1251, club_name = "test" },
        { cid = 1243, club_name = "test" },
        { cid = 1249, club_name = "test" },
        { cid = 1248, club_name = "test" },
        { cid = 1247, club_name = "test" },
        { cid = 1246, club_name = "test" },
        { cid = 1245, club_name = "test" },
        { cid = 1244, club_name = "test" }
    },
    ["dev"] = {
        { cid = 1221, club_name = "test" },
        { cid = 1220, club_name = "test" },
        { cid = 1219, club_name = "test" },
        { cid = 1218, club_name = "test" },
        { cid = 1217, club_name = "test" },
        { cid = 1216, club_name = "test" },
        { cid = 1215, club_name = "test" },
        { cid = 1214, club_name = "test" },
        { cid = 1213, club_name = "test" },
        { cid = 1212, club_name = "test" }
    }
}

root.NEED_BET_BEFORE_NUO_OF_YES = NEED_BET_BEFORE_NUO_OF_YES
root.NEED_BET_BEFORE_NUO_OF_NO = NEED_BET_BEFORE_NUO_OF_NO
root.NEED_BET_BEFORE_NUO_LIST = {
    { value = NEED_BET_BEFORE_NUO_OF_YES, name = "挪之前须要下注"},
    { value = NEED_BET_BEFORE_NUO_OF_NO, name = "挪之前不需要下注"},
}
root.NEED_BET_AMOUNT_BEFORE_NUO = 1000

return root
